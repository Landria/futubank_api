require "spec_helper"

RSpec.describe FutubankAPI do
  FutubankAPI::Client.merchant_id    = 'miliru'
  FutubankAPI::Client.secret_key     = '79444967C3C5ABC438E0E187AC4D0B5B'
  FutubankAPI::Client.base_url       = "https://secure.futubank.com/api/v1"
  FutubankAPI::Client.testing        = 1

  let(:params) do
    {
      PAN: '4809386824280323', month: 12, year: 24, CVV: '547',
      amount: 250.00, cardholder_name: 'John Doe',
      order_id: 'Some_order_id', client_ip: '192.168.10.2',
      client_id: '45464600'
    }
  end

  it "has a version number" do
    expect(FutubankAPI::VERSION).not_to be nil
  end

  describe '.pay' do
    context 'errors' do
      it 'should not be ok if signature is not correct' do
        # Ответ при неверной подписи
        # {
        #   "field_errors": {},
        #   "form_errors": [
        #     "Неверное значение поля signature"
        #   ],
        #   "message": "Неверное значение поля signature",
        #   "status": "error"
        # }
        stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(:status => 200,
          :body => "{\n  \"field_errors\": {}, \n  \"form_errors\": [\n    \"\xD0\x9D\xD0\xB5\xD0\xB2\xD0\xB5\xD1\x80\xD0\xBD\xD0\xBE\xD0\xB5 \xD0\xB7\xD0\xBD\xD0\xB0\xD1\x87\xD0\xB5\xD0\xBD\xD0\xB8\xD0\xB5 \xD0\xBF\xD0\xBE\xD0\xBB\xD1\x8F signature\"\n  ], \n  \"message\": \"\xD0\x9D\xD0\xB5\xD0\xB2\xD0\xB5\xD1\x80\xD0\xBD\xD0\xBE\xD0\xB5 \xD0\xB7\xD0\xBD\xD0\xB0\xD1\x87\xD0\xB5\xD0\xBD\xD0\xB8\xD0\xB5 \xD0\xBF\xD0\xBE\xD0\xBB\xD1\x8F signature\", \n  \"status\": \"error\"\n}"
        )
        params[:client_uniq_id] = '789798798797'
        response = FutubankAPI::Client.payment(params)
        expect(response.ok?).to be_falsey
        expect(response.message).to eq "Неверное значение поля signature"
      end

      it 'should has connectivity_issue when parsing errors' do
        stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(:status => 200, :body => '<h1>Not Found</h1><p>The requested URL /api/v1 was not found on this server.</p>')

        response = FutubankAPI::Client.payment(params)
        expect(response.connectivity_issue?).to be_truthy
        expect(response).to be_a(FutubankAPI::Response)
      end

      it 'should has connectivity issue if path not found' do
        stub_request(:post,"https://secure.futubank.com/api/v1/payment").to_return(:status => 404)

        response = FutubankAPI::Client.payment(params)
        expect(response.connectivity_issue?).to be_truthy
        expect(response.ok?).to be_falsey
        expect(response).to be_a(FutubankAPI::Response)
      end
    end

    context 'return successful' do
      # Ответ на payment запрос для карты с 3DS
      # {
      #   "status": "ok",
      #   "transaction": {
      #     "MD": "01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==",
      #     "PaReq": "eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=",
      #     "acs_url": "https://mpit.minbank.ru/PaReqVISA.jsp",
      #     "state": "WAITING_FOR_3DS",
      #     "transaction_id": "2ERx0LdNLSVcGMfzk5NRW7"
      #   }
      # }

      before {
        stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(
          :status => 200,
         :body => "{\"status\": \"ok\", \n  \"transaction\": {\"MD\": \"01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==\", \n  \"PaReq\": \"eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=\", \n  \"acs_url\": \"https://mpit.minbank.ru/PaReqVISA.jsp\",\n\"state\": \"WAITING_FOR_3DS\",\n\"transaction_id\": \"2ERx0LdNLSVcGMfzk5NRW7\"\n}\n}")
      }

      it 'should return Response' do
        expect(FutubankAPI::Client.payment(params)).to be_a(FutubankAPI::Response)
      end

      it 'should be successful' do
        expect(FutubankAPI::Client.payment(params).ok?).to be_truthy
      end

      describe '#payment' do
        context 'return' do
          it 'should return be successful' do
            client = FutubankAPI::Client.new(params)
            expect(client.payment.ok?).to be_truthy
            expect(client.payment.connectivity_issue?).to be_falsey
          end

          it 'should has connectivity issue if path not found' do
            stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(:status => 404)
            client = FutubankAPI::Client.new(params)
            expect(client.payment.connectivity_issue?).to be_truthy
            expect(client.payment.ok?).to be_falsey
            expect(client.payment).to be_a(FutubankAPI::Response)
          end

          it 'has an error_code when failed' do
            # Ответ на finish-3ds
              # {
              #   "message": null,
              #   "status": "error",
              #   "transaction": {
              #     "amount": "123.00",
              #     "auth_code": null,
              #     "created_datetime": "2017-05-29 15:36:06.020159+00:00",
              #     "currency": "RUB",
              #     "message": null,
              #     "meta": "",
              #     "mps_error_code": '055',
              #     "order_id": "Some_order_id",
              #     "pan_mask": "480938******0323",
              #     "payment_method": "card",
              #     "payment_token": "",
              #     "recurring_token": "",
              #     "response_action": null,
              #     "state": "FAILED",
              #     "testing": 1,
              #     "transaction_id": "2ERx0LdNLSVcGMfzk5NRW7"
              #   }
            # }


            stub_request(:post, "https://secure.futubank.com/api/v1/payment").
              to_return(:status => 200, :body => "{\n  \"message\": null, \n  \"status\": \"error\", \n  \"transaction\": {\n    \"amount\": \"123.00\", \n    \"auth_code\": null, \n    \"created_datetime\": \"2017-05-29 15:36:06.020159+00:00\", \n    \"currency\": \"RUB\", \n    \"message\": null, \n    \"meta\": \"\", \n    \"mps_error_code\": \"055\", \n    \"order_id\": \"Some_order_id\", \n    \"pan_mask\": \"480938******0323\", \n    \"payment_method\": \"card\", \n    \"payment_token\": \"\", \n    \"recurring_token\": \"\", \n    \"response_action\": null, \n    \"state\": \"FAILED\", \n    \"testing\": 1, \n    \"transaction_id\": \"2ERx0LdNLSVcGMfzk5NRW7\"\n  }\n}")

            client = FutubankAPI::Client.new(params)
            response = client.payment

            expect(response.error?).to be_truthy
            expect(response.error_code).to eq "055"
          end
        end


      end
    end

  end

  describe '#method_missing' do
    it 'should return raise NoMethodError if method not found' do
      client = FutubankAPI::Client.new(params)
      expect { client.wrong_method }.to raise_error(NoMethodError)
    end
  end

  context '#refund' do
    it 'returns params error' do
      # Ответ при запросе с пустыми параметрам
      # {
      #   "message": "Не заполнены поля: транзакция; Сумма возврата: введите число.; Неверное значение поля signature",
      #   "status": "error"
      # }

      stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(
         :status => 200,
         :body => "{\"status\": \"ok\", \n  \"transaction\": {\"MD\": \"01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==\", \n  \"PaReq\": \"eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=\", \n  \"acs_url\": \"https://mpit.minbank.ru/PaReqVISA.jsp\",\n\"state\": \"WAITING_FOR_3DS\",\n\"transaction_id\": \"2ERx0LdNLSVcGMfzk5NRW7\"\n}\n}"
      )

      stub_request(:post, "https://secure.futubank.com/api/v1/refund").
        to_return(:status => 200, :body => '{"message": "Не заполнены поля: транзакция; Сумма возврата: введите число.; Неверное значение поля signature",   "status": "error"}', :headers => {})

      response = FutubankAPI::Client.refund({})
      expect(response.response_code).to eq('error')
      expect(response.message).to eq('Не заполнены поля: транзакция; Сумма возврата: введите число.; Неверное значение поля signature')
    end

    it 'refunds successfully' do
      # Ответ при запросе с верными параметрами
      # BODY = {
      #   "message": null,
      #   "status": "ok",
      #   "transaction": {
      #     "amount": "123.00",
      #     "auth_code": null,
      #     "created _datetime": "2017-05-29 15:36:06.020159+00:00",
      #     "currency": "RUB",
      #     "message": null,
      #     "meta": "",
      #     "mps_error_code": null,
      #     "order_id": "Some_order_id",
      #     "pan_mask": "480938******0323",
      #     "payment_method": "card",
      #     "payment_token": "",
      #     "recurring_token": "",
      #     "response_action": null,
      #     "state": "COMPLETE",
      #     "testing": 1,
      #     "transaction_id": "2ERx0LdNLSVcGMfzk5NRW7"
      #   }
      # }

      stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(
        :status => 200,
        :body => "{\"status\": \"ok\", \n  \"transaction\": {\"MD\": \"01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==\", \n  \"PaReq\": \"eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=\", \n  \"acs_url\": \"https://mpit.minbank.ru/PaReqVISA.jsp\",\n\"state\": \"WAITING_FOR_3DS\",\n\"transaction_id\": \"2ERx0LdNLSVcGMfzk5NRW7\"\n}\n}"
      )

      stub_request(:post, "https://secure.futubank.com/api/v1/refund").
        to_return(:status => 200, :body =>  '{"message": null,"status": "ok","transaction": {"amount": "123.00","auth_code": null,"created _datetime": "2017-05-29 15:36:06.020159+00:00","currency": "RUB","message": null,"meta": "","mps_error_code": null,"order_id": "Some_order_id","pan_mask": "480938******0323","payment_method": "card","payment_token": "","recurring_token": "","response_action": null,"state": "COMPLETE","testing": 1,"transaction_id": "2ERx0LdNLSVcGMfzk5NRW7"}}', :headers => {})

      params = { transaction: '2ERx0LdNLSVcGMfzk5NRW7', amount: 100.50 }

      response = FutubankAPI::Client.refund(params)
      expect(response.ok?).to be_truthy
      expect(response.response_code).to eq('ok')
    end
  end

  context '#finish-3ds' do
    # Ответ на payment запрос для карты с 3DS
      # {
      #   "status": "ok",
      #   "transaction": {
      #     "MD": "01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==",
      #     "PaReq": "eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=",
      #     "acs_url": "https://mpit.minbank.ru/PaReqVISA.jsp",
      #     "state": "WAITING_FOR_3DS",
      #     "transaction_id": "2ERx0LdNLSVcGMfzk5NRW7"
      #   }
      # }

    it 'gets 3ds transaction reply' do
      stub_request(:post, "https://secure.futubank.com/api/v1/payment").to_return(
        :status => 200,
        :body => "{\"status\": \"ok\", \n  \"transaction\": {\"MD\": \"01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==\", \n  \"PaReq\": \"eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=\", \n  \"acs_url\": \"https://mpit.minbank.ru/PaReqVISA.jsp\",\n\"state\": \"WAITING_FOR_3DS\",\n\"transaction_id\": \"2ERx0LdNLSVcGMfzk5NRW7\"\n}\n}"
      )
      client = FutubankAPI::Client.new(params)
      response = client.payment
      expect(response.three_ds?).to be_truthy
    end

    it 'finish-3ds successfully' do
      # Ответ на finish-3ds
      # {
      #   "message": null,
      #   "status": "ok",
      #   "transaction": {
      #     "amount": "123.00",
      #     "auth_code": null,
      #     "created_datetime": "2017-05-29 15:36:06.020159+00:00",
      #     "currency": "RUB",
      #     "message": null,
      #     "meta": "",
      #     "mps_error_code": null,
      #     "order_id": "Some_order_id",
      #     "pan_mask": "480938******0323",
      #     "payment_method": "card",
      #     "payment_token": "",
      #     "recurring_token": "",
      #     "response_action": null,
      #     "state": "FAILED",
      #     "testing": 1,
      #     "transaction_id": "2ERx0LdNLSVcGMfzk5NRW7"
      #   }
      # }

      params = { "MD": "01LF6LQBATXnLRVmIiUZBA/H0uqjLW2b4WGbGUeeUKOVjOQ3R7XTIkV3hNkaxSArXfSZlBvCsTsFx2EA46uXixo14O6SEPbOoCRC1xVn90Z4EuFuogvVpyp164sWEolrbeAdblc46iZztcao3ADnkGJB3nQPydXWA8L88kel3svLCG+jlAKl1NV7Ch++5hDVzPY+PTBXzwo+h6Wj7SgI4MQMw3Uaeru6GojErYGj8Bm8LS76Jvy3seNuz2MyGszA1uJppqxr0d0qUAy/EpwHGnItNp5w9JI4T4yb+1eam91mnMFBoJvsaRgziC0A3PxiGagM22bLRXWQ4G0fxjeYUWZ2gY9LJiM3qVYg2ShzKFCmRjhH45CVpJ8eIdExu2AK0Kq0TfoC5Mu5aGUgBWAuPA==",
                 "PaRes": "eJxVUk1zgjAQPfsvmPZOQsAPnJgZWw/1gFL1zlDY0VgJmECr/77ZKI5lJjO772Uf2bfLdwcNsNhC0WkQPAFj8j14spy9pPMNnLMgikd0zBiL6TB+EQPuYDEY8B/QRtZKBD71GSd9apkEdHHIVWvjAc+L89tyJSLKQjbm5J4iU4FeLkS63mYBJ7cEYZVX0KMuRrCoO9XqqxhFISd9gkSnT+LQto2ZElI1svUrqb5y9e3rbhrZjyTpkmzANLUykOq6sB1KtfePpuEEi60GeXowTzuMze23JZhCpPm1AtV6iTxJK+vVugTtbesKMhdmsuTE3cSSiyxFsvscro7zMDkur+vdPLDnN1m4M+MEbzjxvAXBaDCmQxZ7wWQajqc0tlKIO+sqbFQELPQptdbdUmQafOT8QSP7DDnHOq1BFb1lfYYUXKwbtiNhx/aI0Yen3vn7x318RWsHE01oHE5eJyMWjtwUHXoXk3YWLApuatINhhOst4puW9Bht1g2+rdwf02cwe0=" }
      stub_request(:post, "https://secure.futubank.com/api/v1/finish-3ds").to_return(:status => 200, :body => "{\n  \"message\": null, \n  \"status\": \"ok\", \n  \"transaction\": {\n    \"amount\": \"123.00\", \n    \"auth_code\": null, \n    \"created_datetime\": \"2017-05-29 15:36:06.020159+00:00\", \n    \"currency\": \"RUB\", \n    \"message\": null, \n    \"meta\": \"\", \n    \"mps_error_code\": null, \n    \"order_id\": \"Some_order_id\", \n    \"pan_mask\": \"480938******0323\", \n    \"payment_method\": \"card\", \n    \"payment_token\": \"\", \n    \"recurring_token\": \"\", \n    \"response_action\": null, \n    \"state\": \"FAILED\", \n    \"testing\": 1, \n    \"transaction_id\": \"2ERx0LdNLSVcGMfzk5NRW7\"\n  }\n}")
      client = FutubankAPI::Client.new(params)
      response = client.finish_3ds
      expect(response.ok?).to be_truthy
    end

    it 'finish-3ds with error' do
      params = { "MD": "112317-FD62EF9285BBF564FD62EF9285BBF564FD62EF9285BBF564456+78965", "PaRes": "eJxVUl1v4jAQeJxVUl1v4jAQeJxVUl1v4jAQeJxVUl1v4jAQ" }
      stub_request(:post, "https://secure.futubank.com/api/v1/finish-3ds").to_return(:status => 200, :body => "{\n  \"message\": \"MD: \xD0\xB2\xD0\xB2\xD0\xB5\xD0\xB4\xD0\xB8\xD1\x82\xD0\xB5 \xD0\xBF\xD1\x80\xD0\xB0\xD0\xB2\xD0\xB8\xD0\xBB\xD1\x8C\xD0\xBD\xD0\xBE\xD0\xB5 \xD0\xB7\xD0\xBD\xD0\xB0\xD1\x87\xD0\xB5\xD0\xBD\xD0\xB8\xD0\xB5.\", \n  \"status\": \"error\"\n}")
      client = FutubankAPI::Client.new(params)
      response = client.finish_3ds
      expect(response.ok?).to be_falsey
      expect(response.message).to eq "MD: введите правильное значение."
    end
  end

  context 'get_state' do
    it 'gets nil if transaction not exists' do
      time = 1496337631

      stub_request(:any, "https://secure.futubank.com/api/v1/transaction?merchant=miliru&salt=Z3hrZG1wa&signature=586990308641dfbd78fc8d71d6d9e74f76ba5222&transaction_id=2ERx0LdNLSVc0000001&unix_timestamp=#{time}").
        to_return(:status => 200, :body => '{"message": "Unknown transaction", "status": "error"}', :headers => {})

      client = FutubankAPI::Client.new unix_timestamp: time, salt: 'Z3hrZG1wa'
      expect(client.transaction('2ERx0LdNLSVc0000001').state).to eq nil
    end

    it 'gets state if transaction exists' do
      time = 1496337631

      stub_request(:any, "https://secure.futubank.com/api/v1/transaction?merchant=miliru&salt=Z3hrZG1wa&signature=586990308641dfbd78fc8d71d6d9e74f76ba5222&transaction_id=2ERx0LdNLSVc0000001&unix_timestamp=#{time}").
        to_return(:status => 200, :body => '{ "status": "ok", "transaction": {"amount": "123.00", "auth_code": null, "commission": "3.57", "completed_datetime": null, "created_datetime": "2017-05-29 15:36:06.020159+00:00", "currency": "RUB", "description": "Mili.ru order Some_order_id", "message": null, "meta": "", "mps_error_code": null, "order_id": "Some_order_id", "pan_mask": "480938******0323", "payment_method": "card", "payment_token": "", "recurring_finish_date": "", "recurring_frequency": "", "recurring_initial_transaction": "", "recurring_token": "", "response_action": null, "state": "FAILED", "testing": 1, "transaction_id": "2ERx0LdNLSVcGMfzk5NRW7", "updated_datetime": "2017-05-29 16:25:24.577053+00:00"}}', :headers => {})

      client = FutubankAPI::Client.new unix_timestamp: time, salt: 'Z3hrZG1wa'
      expect(client.transaction('2ERx0LdNLSVc0000001').state).to eq 'FAILED'
    end
  end
end

