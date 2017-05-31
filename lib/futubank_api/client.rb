require 'digest/sha1'
require 'faraday'
require 'nokogiri'
require 'active_support'
require 'active_support/all'

module FutubankAPI
  class Client
    class_attribute :base_url
    class_attribute :secret_key
    class_attribute :merchant_id
    class_attribute :success_url
    class_attribute :fail_url
    class_attribute :cancel_url
    class_attribute :testing
    class_attribute :logger

    METHODS = %w(payment finish-3ds refund).freeze

    ACTIONS = {
      'payment': %w[
        merchant
        currency
        payment_method
        salt
        unix_timestamp
        testing
        description
        amount
        PAN
        order_id
        client_id
        month
        year
        CVV
        cardholder_name
        client_ip
      ],

      'finish-3ds': %w[MD PaRes],

      'refund': %w[
        merchant
        amount
        transaction
        salt
        unix_timestamp
      ]
    }.freeze

    CURRENCY = 'RUB'
    PAYMENT_METHOD = 'card'

    def initialize(order_params={})
      @order_params = order_params
      params = {
        merchant: self.class.merchant_id,
        currency: CURRENCY,
        payment_method: PAYMENT_METHOD,
        salt: salt,
        unix_timestamp: Time.now.to_i,
        testing: self.class.testing,
        description: description
      }

      @params = @order_params.merge params
    end

    class << self
      METHODS.each do |m|
        define_method(m) { |*args| instance = new(*args); instance.send(m) }
      end
    end

    def payment
      request('payment')
    end

    def finish_3ds
      request('finish-3ds')
    end

    def refund
      request('refund')
    end

    private
      def actions
       ACTIONS.with_indifferent_access
      end

      def preapre_params(action)
        params = @params.clone.keep_if { |field, _| actions[action].include? field.to_s }
        params[:signature] = signature(params)
        params
      end

      def request(path)
        response = connection.post path, preapre_params(path)
        #FutubankAPI.logger.info "Futubank response: #{response.inspect}. Futubank timeout = #{FutubankAPI.timeout}"
        #raise FutubankAPI::Error, "http response code #{response.status}" unless response.status == 200
        Response.new response
      rescue Faraday::Error::TimeoutError, Timeout::Error, StandardError => exception
        #FutubankAPI.logger.info "Futubank error: #{exception.message}. Futubank timeout = #{FutubankAPI.timeout}"
        exception.extend FutubankAPI::Error
        exception
      end

      def connection
        Faraday.new(self.class.base_url) do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
        end
      end

      def signature(params)
        hash = {}

        params.map do |k, v|
          hash[k.to_s] = Base64.encode64(v.to_s) if v.present?
        end

        values = Hash[hash.sort].map { |k, v| "#{k}=#{v}" }.join('&')
        values.gsub!("\n", '')
        puts "VALUES = #{values.inspect}"

        Digest::SHA1.hexdigest(self.secret_key + (Digest::SHA1.hexdigest(self.secret_key + values)))
      end

      def salt
        Base64.encode64((0...45).map { ('a'..'z').to_a[rand(26)] }.join)
      end

      def description
        "Mili.ru order #{@order_params[:order_id]}"
      end
  end
end
