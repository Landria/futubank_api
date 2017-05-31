module FutubankAPI
  module Configuration
    DEFAULT_TIMEOUT = 10
    #DEFAULT_LOGGER = ::Logger.new($stdout)
    attr_accessor :timeout, :logger

    def configure
      yield self
    end

    def self.extended base
      base.reset
    end

    def reset
      self.timeout = DEFAULT_TIMEOUT
      #self.logger  = DEFAULT_LOGGER
      #self.logger.level = Logger::ERROR
      self
    end
  end
end
