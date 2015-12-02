require "apn/connection"

module APN
  class Application
    include Connection
    APPS             = {}
    OPTION_KEYS      = [:pool_size, :pool_timeout, :host, :port, :root, :password, :certificate_name, :full_certificate_path].freeze
    DELEGATE_METHODS = [:with_connection, :connection_pool, :certificate].concat(OPTION_KEYS).freeze

    def self.register(*args, &block)
      new(*args, &block).tap do |app|
        APPS[app.name] = app if app.certificate
      end
    end

    attr_reader :name

    def initialize(name, options = nil) # :yields:
      @name          = name.to_s.freeze
      @pool_size     = APN.original_pool_size
      @pool_timeout  = APN.original_pool_timeout
      @host          = APN.original_host
      @port          = APN.original_port
      @root          = APN.original_root
      @password      = APN.original_password
      @cert_name     = APN.original_certificate_name
      # @full_certificate_path = APN.original_full_certificate_path

      self.attributes = options if options.is_a? Hash
      yield(self)               if block_given?
    end

    def attributes= options
      options.each do |attribute_name, value|
        public_send(:"#{attribute_name}=", value)
      end
    end

    def to_h
      Hash[OPTION_KEYS.map do |attribute_name|
        [attribute_name, public_send(name)]
      end]
    end

    def == other
      if other.is_a? APN::Application
        to_h == other.to_h
      else
        super
      end
    end
  end
end