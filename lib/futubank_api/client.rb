require 'digest/sha1'
require 'faraday'
require 'nokogiri'
require 'active_support'
require 'active_support/all'

module FutubankAPI
  class Client
    class_attribute :base_url
    class_attribute :refund_url
    class_attribute :secret_key
    class_attribute :merchant_id
    class_attribute :success_url
    class_attribute :fail_url
    class_attribute :cancel_url
    class_attribute :testing

    METHODS = %w(pay refund)
    CURRENCY = 'RUB'
    PAYMENT_METHOD = 'card'

    def initialize(order_params={})
      params = {
        merchant: self.class.merchant_id,
        currency: CURRENCY,
        payment_method: PAYMENT_METHOD,
        success_url: self.class.success_url,
        fail_url: self.class.fail_url,
        cancel_url: self.class.cancel_url,
        salt: salt,
        unix_timestamp: Time.now.to_i,
        testing: self.class.testing
      }

      @params = order_params.merge params
    end

    METHODS.each do |m|
      define_method(m) { request(m.camelize) }
    end

    class << self
      METHODS.each do |m|
        define_method(m) { |*args| instance = new(*args); instance.send(m) }
      end
    end

    def method_missing(m)
      val = instance_variable_get("@#{m}")
      val.nil? ? super : val
    end

    private
      def request(path)
        response = Faraday.new(url: self.class.base_url).get do |req|
          req.options[:timeout]      = FutubankAPI.timeout
          req.options[:open_timeout] = FutubankAPI.timeout
          req.url '', prepare_params
        end

        puts "PARAMS = #{prepare_params.map { |k,v| "#{k}=#{v}" }.join('&').inspect}"
        puts "RESPONSE = #{response.inspect}"

        #FutubankAPI.logger.info "Futubank response: #{response.inspect}. Futubank timeout = #{FutubankAPI.timeout}"

        raise FutubankAPI::Error, "http response code #{response.status}" unless response.status == 200
        Response.new response
      rescue Faraday::Error::TimeoutError, Timeout::Error, StandardError => exception
        #FutubankAPI.logger.info "Futubank error: #{exception.message}. Futubank timeout = #{FutubankAPI.timeout}"
        exception.extend FutubankAPI::Error
        exception
      end

      def prepare_params
        hash = {}

        @params.map do |k, v|
          hash[k.to_s.camelize] = v.is_a?(Hash) ? v.map{|k,v| "#{k.to_s.camelize}=#{v}"}.join(';') : v
        end

        hash.merge signature: signature(hash)
        hash
      end

      def signature(hash)
        values = Hash[hash.sort].map { |k, v| "#{k}=#{Base64.encode64(v.to_s)}" }.join('&')
        Digest::SHA1.hexdigest(self.secret_key + (Digest::SHA1.hexdigest(self.secret_key + values)).downcase)
      end

      def salt
        Base64.encode64((0...50).map { ('a'..'z').to_a[rand(26)] }.join)
      end

      def description
        "Mili.ru order #{@params[:order_id]}"
      end
  end
end
