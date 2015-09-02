require 'json'

module APN
  class Notification
    MAXIMUM_PAYLOAD_SIZE = 2048
    DEFAULT_SOUND        = 'default'.freeze
    TRUE_VALUES          = [1, true, '1', 'true'].freeze
    MESSAGE_PACK         = 'cNa*'.freeze
    DEVICE_TOKEN_PACK    = 'cnH64'.freeze
    PAYLOAD_PACK         = 'cna*'.freeze
    NUMBER_PACK          = 'cnN'.freeze
    PRIORITY_PACK        = 'cnc'.freeze
    TOKEN_SANITIZE       = '^A-Za-z0-9'.freeze

    attr_accessor :token, :payload, :id, :expiry, :priority
    attr_reader :sent_at
    attr_writer :apns_error_code

    alias :device :token
    alias :device= :token=

    def initialize(token, options = nil)
      @token = token

      if options.is_a?(Hash)
        options   = options.to_options
        @expiry   = options.delete(:expiry)
        @priority = options.delete(:priority)
        @payload  = build_payload(options).to_json
      else
        @payload = build_payload(alert: options).to_json
      end
    end

    def token
      @token.to_s.delete(TOKEN_SANITIZE)
    end

    def build_payload(alert: nil, badge: nil, content_available: nil, sound: nil, **data)
      if data[:aps].is_a?(Hash)
        data[:aps].to_options!
      else
        data[:aps] = {}
      end

      if alert
        data[:aps][:alert] = alert
      end

      if badge
        data[:aps][:badge] = badge.to_i
      end

      if sound
        data[:aps][:sound] = sound.is_a?(TrueClass) ? DEFAULT_SOUND : sound
      end

      if content_available && TRUE_VALUES.include?(content_available)
        data[:aps]['content-available'] = 1
      end

      data
    end

    def message
      data = "#{device_token_item}#{payload_item}#{identifier_item}#{expiration_item}#{priority_item}".freeze
      [2, data.bytesize, data].pack(MESSAGE_PACK)
    end

    def mark_as_sent!
      @sent_at = Time.now
    end

    def mark_as_unsent!
      @sent_at = nil
    end

    def sent?
      !!@sent_at
    end

    def valid?
      payload.bytesize <= MAXIMUM_PAYLOAD_SIZE
    end

    def error
      APN::ServerError.new(@apns_error_code) if @apns_error_code and @apns_error_code.nonzero?
    end

    def device_token_item
      [1, 32, token].pack(DEVICE_TOKEN_PACK)
    end

    private

    def payload_item
      [2, payload.bytesize, payload].pack(PAYLOAD_PACK)
    end


    def identifier_item
      [3, 4, @id.to_i].pack(NUMBER_PACK) unless @id.nil?
    end

    def expiration_item
      [4, 4, @expiry.to_i].pack(NUMBER_PACK) unless @expiry.nil?
    end

    def priority_item
      [5, 1, @priority.to_i].pack(PRIORITY_PACK) unless @priority.nil?
    end
  end
end
