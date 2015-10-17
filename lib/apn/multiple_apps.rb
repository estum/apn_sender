require "apn/application"

module APN
  module MultipleApps
    def self.extended(mod)
      class << mod
        alias_method_chain :notify_sync, :app
        alias_method_chain :debug_sending, :app

        delegate(*Application::DELEGATE_METHODS, to: :current_app, prefix: true, allow_nil: true)

        Application::DELEGATE_METHODS.each do |method_name|
          alias_method :"original_#{method_name}", method_name
          alias_method method_name, :"current_app_#{method_name}"
        end
      end
    end

    def notify_sync_with_app(token, opts)
      app_name = token.pop if token.is_a?(Array)

      with_app(app_name) do
        notify_sync_without_app(*token, opts)
      end
    end

    attr_writer :default_app_name
    
    DEFAULT ||= 'default'.freeze

    def default_app_name
      @default_app_name ||= DEFAULT
    end

    def current_app_name
      Thread.current[:app_name] || default_app_name
    end

    def current_app
      Application::APPS[current_app_name] or \
        raise NameError, "Unregistered APN::Application `#{current_app_name}'"
    end

    def with_app(app_name)
      Thread.current[:app_name] = app_name.presence
      yield if block_given?
    ensure
      Thread.current[:app_name] = nil
    end

    def debug_sending_with_app(token, msg)
      APN.logger.debug { "Sending message '#{msg.payload}' to token '#{token}' for app '#{current_app_name}'" }
    end
  end
end

APN.extend APN::MultipleApps
