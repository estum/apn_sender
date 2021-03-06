require "openssl"
require "socket"
require "active_support"
require "active_support/core_ext"
require "active_support/json"
require 'connection_pool'

require "apn/version"
require "apn/connection"
require "apn/errors"

module APN
  class << self
    include APN::Connection

    def notify_async(token, opts)
      backend.notify(*token, opts)
    end

    def notify_sync(token, opts)
      msg = APN::Notification.new(token, opts)
      raise APN::InvalidNotification unless msg.valid?

      debug_sending(token, msg)

      APN.with_connection do |client|
        client.push(msg)
      end
    end

    def backend=(backend)
      @backend =
        case backend
        when Symbol
          APN::Backend.const_get(backend.to_s.camelize).new
        when nil
          APN::Backend::Simple.new
        else
          backend
        end
    end

    def backend
      @backend ||= APN::Backend::Simple.new
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    # Log message to any logger provided by the user (e.g. the Rails logger).
    # Accepts +log_level+, +message+, since that seems to make the most sense,
    # and just +message+, to be compatible with Resque's log method and to enable
    # sending verbose and very_verbose worker messages to e.g. the rails logger.
    #
    # Perhaps a method definition of +message, +level+ would make more sense, but
    # that's also the complete opposite of what anyone comming from rails would expect.
    def log(level, message = nil)
      level, message = 'info', level if message.nil? # Handle only one argument if called from Resque, which expects only message

      return false unless logger && logger.respond_to?(level)
      logger.send(level, "#{Time.now}: #{message}")
    end

    def debug_sending(token, msg)
      APN.logger.debug { "Sending message '#{msg.payload}' to token '#{token}'" }
    end

    # Log the message first, to ensure it reports what went wrong if in daemon mode.
    # Then die, because something went horribly wrong.
    def log_and_die(msg)
      logger.fatal(msg)
      raise msg
    end
  end
end

require 'apn/multiple_apps' if ENV['APN_MULTIPLE_APPS'] == 'true'
require 'apn/notification'
require 'apn/client'
require 'apn/feedback'

module APN::Jobs
  QUEUE_NAME = :apple_push_notifications
end

require "apn/railtie" if defined?(Rails)
require 'apn/backend'
