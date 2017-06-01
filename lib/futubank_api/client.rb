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
      ],

      'transaction': %w[
        transaction_id
        merchant
        unix_timestamp
        salt
      ]
    }.freeze

    CURRENCY = 'RUB'.freeze
    PAYMENT_METHOD = 'card'.freeze

    def initialize(order_params={})
      @order_params = order_params
      params = {
        merchant: self.class.merchant_id,
        currency: CURRENCY,
        payment_method: PAYMENT_METHOD,
        salt: salt,
        unix_timestamp: Time.now.to_i,
        testing: self.class.testing || 0,
        description: description
      }

      @params = params.merge @order_params
    end

    class << self

      METHODS.each do |m|
        define_method(m) { |*args| instance = new(*args); instance.send(m) }
      end

      def transaction(transaction_id)
        new.transaction(transaction_id)
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

    # Пока метод не работает корректно - api отвечает, то метода нет
    def transaction(transaction_id)
      @params[:transaction_id] = transaction_id
      request('transaction', :get)
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

      def request(path, req_type = :post)
        response = connection.send(req_type, path, preapre_params(path))
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

        Digest::SHA1.hexdigest(self.secret_key + (Digest::SHA1.hexdigest(self.secret_key + values)))
      end

      def salt
        Base64.encode64((0...45).map { ('a'..'z').to_a[rand(26)] }.join)
      end

      def description
        "Mili.ru order #{@order_params[:order_id]}" if @order_params&.dig(:order_id)
      end
  end
end
