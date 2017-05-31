# FutubankApi

Простой gem для процесинга карточек через Futubank

## Установка

Добавить в Gemfile:

    gem 'futubank_api', git: 'ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/futubank_api'

Затем запустить:

    $ bundle install

## Конфигурация

Конфигурировать можно так:

    FutubankAPI.configure do |config|
      config.timeout = 12 # seconds
    end

    FutubankAPI.timeout          # => 12

А можно и так:

    FutubankAPI.timeout = 2
    FutubankAPI.timeout          # => 2

## Использование

Установите базовый адрес для запросов и ключ мерчанта

    FutubankAPI::Client.base_url = "https://secure.futubank.com/api/v1"
    FutubankAPI::Client.key = "MerchantKey"
    FutubankAPI::Client.secret_key = "MerchantSecretKey"

Выполнять запросы можно двумя способами:

    params = {
      PAN: '4809386824280323',
      month: 12,
      year: 24,
      CVV: '547',
      amount: 250.00,
      cardholder_name: 'John Doe',
      order_id: 'Some_order_id',
      client_ip: '192.168.10.2',
      client_id: '45464600'
    }

    PaytureAPI::Client.payment(params)

Или же

    client = FutubankAPI::Client.new
    client.payment(params)

## Контрибьют

1. Fork it
2. Create your feature branch (`git checkout -b feature-JIRA-ID`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
