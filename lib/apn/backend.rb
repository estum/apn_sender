module APN
  module Backend
    autoload :Sidekiq,     'apn/backend/sidekiq'
    autoload :Resque,      'apn/backend/resque'

    class Simple
      def notify(*args)
        Thread.new do
          APN.notify_sync(*args)
        end
      end
    end

    class Null
      def notify(*args)
        APN.logger.info { "Null Backend sending message #{token}" }
      end
    end
  end
end
