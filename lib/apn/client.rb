module APN
  class Client

    DEFAULTS = {port: 2195, host: "gateway.push.apple.com"}

    def initialize(options = {})
      options = DEFAULTS.merge options.reject{|k,v| v.nil?}
      @apn_cert, @cert_pass = options[:certificate], options[:password]
      @host, @port = options[:host], options[:port]
      self
    end

    def push(notification)
      return unless notification.kind_of?(Notification)
      return if notification.sent?
      return unless notification.valid?

      socket.write(notification.message)
      # socket.flush

      notification.mark_as_sent!

      read_socket, write_socket = IO.select([socket], [socket], [socket], nil)
      if (read_socket && read_socket[0])
        if error = socket.read(6)
          command, status, index = error.unpack("ccN")
          notification.apns_error_code = status
          notification.mark_as_unsent!
          raise notification.error
        end
      end

      APN.logger.debug { "Message sent." }
      notification

    rescue APN::ServerError => e
      APN.logger.error { "Error on message: #{e}" }
      false

    rescue OpenSSL::SSL::SSLError, Errno::EPIPE, Errno::ETIMEDOUT => e
      APN.logger.error { "[##{object_id}] Exception occurred: #{e.inspect}, socket state: #{socket.inspect}" }
      reset_socket
      APN.logger.warn { "[##{object_id}] Socket reestablished, socket state: #{socket.inspect}" }
      retry
    end

    def feedback
      if bunch = socket.read(38)
        f = bunch.strip.unpack('N1n1H140')
        APN::FeedbackItem.new(Time.at(f[0]), f[2])
      end
    end

    def socket
      @socket ||= setup_socket
    end

    private

    # Open socket to Apple's servers
    def setup_socket
      APN.logger.debug { "Connecting to #{@host}:#{@port}..." }

      @context ||= setup_certificate
      @tcp_socket = TCPSocket.new(@host, @port)
      OpenSSL::SSL::SSLSocket.new(@tcp_socket, @context).tap do |ssl|
        ssl.sync = true
        ssl.connect
      end
    end

    def close
      return false if closed?

      @tcp_socket.close
      @tcp_socket = nil

      @socket.close
      @socket = nil
    end

    def open?
      not closed?
    end

    def closed?
      (@tcp_socket and @socket).nil?
    end

    def reset_socket
      close
      socket
    end

    def setup_certificate
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(@apn_cert)
      if @cert_pass
        ctx.key = OpenSSL::PKey::RSA.new(@apn_cert, @cert_pass)
        APN.logger.debug { "Setting up certificate using a password." }
      else
        ctx.key = OpenSSL::PKey::RSA.new(@apn_cert)
      end
      ctx
    end
  end
end
