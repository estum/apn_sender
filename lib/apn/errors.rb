module APN
  GenericError = Class.new(StandardError)

  class InvalidNotification < GenericError
    def initialize
      super "Invalid notification size"
    end
  end

  class ServerError < GenericError
    # See: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW12
    CODES = {
      0 => "No errors encountered",
      1 => "Processing error",
      2 => "Missing device token",
      3 => "Missing topic",
      4 => "Missing payload",
      5 => "Invalid token size",
      6 => "Invalid topic size",
      7 => "Invalid payload size",
      8 => "Invalid token",
      10 => "Shutdown",
      255 => "Unknown error"
    }

    attr_reader :code

    def initialize(code)
      raise ArgumentError unless CODES.include?(code)
      super(CODES[code])
      @code = code
    end
  end
end
