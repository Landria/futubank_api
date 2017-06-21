module FutubankAPI
  class Response

    SUCCESS_VALUES = %w[ok COMPLETE].freeze

    STATES = %w[PROCESSING WAITING_FOR_3DS COMPLETE FAILED].freeze

    # !!! Этот код действителен только для Минбанка, и может измениться  с заменой банка, с которым работат futubank
    DUPLICATE_ORDER_ERROR_CODE = '078'.freeze

    def initialize(response)
      @response = response
      @body = JSON.parse @response.body.force_encoding('utf-8')
    rescue
      @body = { 'errors' => @response.body }
    ensure
      @body ||= { 'errors' => @response.body }
      @body = @body.with_indifferent_access
    end

    def ok?
      !error?
    end

    def connectivity_issue?
      parsing_errors? || @response.status != 200
    end

    def duplicate_order_id?
      error_code == DUPLICATE_ORDER_ERROR_CODE
    end

    def message
      response_message
    end

    def transaction_id
      attributes['transaction_id']
    end

    def state
      attributes['state']
    end

    def error?
      if errors?
        true
      else
        !SUCCESS_VALUES.include? response_code
      end
    end

    def error_code
      attributes['mps_error_code'] if error?
    end

    def three_ds?
      ok? && (attributes['acs_url'] && attributes['PaReq'] && attributes['MD'])
    end

    def three_ds_attributes
      {
        url: attributes['acs_url'],
        pa_req: attributes['PaReq'],
        md: attributes['MD']
      } if three_ds?
    end

    def response_code
      @body['status']
    end

    def response_message
      @body['message'] || attributes['message'] || attributes['state'] || @body
    end

    # parse all attributes from response to Hash
    # example out of this method:
    # ошибка:
    # {"field_errors"=>{"amount"=>"Введите число.", "client_ip"=>"Это поле обязательно.", "currency"=>"Это поле обязательно.", "description"=>"Это поле обязательно.", "merchant"=>"Неверный идентификатор магазина; Поле merchant должно быть заполнено", "month"=>"Это поле обязательно.", "order_id"=>"Это поле обязательно.", "signature"=>"Это поле обязательно.", "unix_timestamp"=>"Это поле обязательно.", "year"=>"Это поле обязательно."}, "form_errors"=>"", "message"=>"Не заполнены поля: месяц окончания действия карты, ip адрес клиента, номер заказа, год окончания действия карты, текущая дата на сервере, идентификатор магазина, криптографическая подпись, описание заказа, валюта операции; Сумма операции: введите число.", "status"=>"error"}
    # транзакция без 3DS
    # {"status": "ok", "transaction": {"transaction_id": 3152,"amount": "100.01", "currency": "RUB","message": "Одобрено","meta": "","order_id": 10001,"state": "COMPLETE","created_datetime": "2014-07-10T06:27:29.815069+00:00","recurring_token": "","testing": "1" // признак тестовой транзакции}}
    # транзакция с 3DS
    # {"status": "ok", "transaction": {"transaction_id": 3154,"acs_url": "https://3ds2.mmbank.ru/acs2/pa?id=375208804008360","state": "WAITING_FOR_3DS","MD": "112317-FD62EF9285BBF564","PaReq": "eJxVUl1v4jAQ  ..... ","TermUrl": ""}}
    def attributes
      @attributes = {}
      (@body['transaction'] || @body).map do |key, value|
        @attributes[key] = value
      end

      @attributes
    end

    private

    def errors?
      @body['errors']&.present? || @body['field_errors']&.present? || @body['form_errors']&.present? || false
    end

    def parsing_errors?
      @body['errors'].present?
    end
  end
end
