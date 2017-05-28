require "spec_helper"

RSpec.describe FutubankAPI do
  FutubankAPI::Client.merchant_id = 'miliru'
  FutubankAPI::Client.secret_key  = '79444967C3C5ABC438E0E187AC4D0B5B'
  FutubankAPI::Client.base_url    = "https://secure.futubank.com/pay"
  FutubankAPI::Client.refund_url    = "https://secure.futubank.com/api/v1/refund"
  FutubankAPI::Client.success_url = '/'
  FutubankAPI::Client.fail_url    = '/'
  FutubankAPI::Client.cancel_url  = '/'
  FutubankAPI::Client.testing     = 1

  let(:params) do
    { :PAN => '4809386824280323', :e_month => '12', :e_year => '2024', :card_holder => 'John Doe', :secure_code => '547',
      :order_id => '12', :order_id => '12', :amount => '123.00' }
  end

  it "has a version number" do
    expect(FutubankAPI::VERSION).not_to be nil
  end

  describe '.pay' do
    context 'errors' do
      it 'should not be ok if key is not correct' do
        #vcr: { cassette_name: 'lib/futubank_api/pay_error' }

        #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Pay/).to_return(:status => 200, :body => '<Pay OrderId="" Success="False" ErrCode="ACCESS_DENIED"/>')
        response = FutubankAPI::Client.pay(params)
        expect(response.ok?).to be_falsey
      end

      it 'should has connectivity_issue when parsing errors' do
        #stub_request(:post, /https\:\/\/secure.futubank.com\/pay/).to_return(:status => 200, :body => 'Bad request')
        response = FutubankAPI::Client.pay(params)
        expect(response.connectivity_issue?).to be_truthy
        expect(response).to be_a(FutubankAPI::Response)
      end

      it 'should has connectivity issue if path not found' do
        #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Pay/).to_return(:status => 404)

        response = FutubankAPI::Client.pay(params)
        expect(response.connectivity_issue?).to be_truthy
        expect(response).to be_a(FutubankAPI::Response)
      end
    end

    context 'return successful' do
      #before { stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Pay/).to_return(:status => 200, :body => '<Pay OrderId="12" Success="True" Amount="12300" />') }

      it 'should return Response' do
        expect(FutubankAPI::Client.pay(params)).to be_a(FutubankAPI::Response)
      end

      it 'should be successful' do
        expect(FutubankAPI::Client.pay(params).ok?).to be_truthy
      end
    end

  end

  describe '#method_missing' do
    it 'should return raise NoMethodError if method not found' do
      #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Pay/).to_return(:status => 200, :body => '<Pay OrderId="12" Success="True" Amount="12300" />')

      client = PaytureAPI::Client.new(params)
      client.pay
      lambda{ client.wrong_method }.should raise_error(NoMethodError)
    end
  end

  describe '#pay' do
    context 'return' do

      it 'should return be successful' do
        #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Pay/).to_return(:status => 200, :body => '<Pay OrderId="12" Success="True" Amount="12300" />')
        client = FutubankAPI::Client.new(params)
        client.pay.ok?.should eq true
      end

      it 'should has connectivity issue if path not found' do
        #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Pay/).to_return(:status => 404)
        client = FutubankAPI::Client.new(params)
        client.pay.connectivity_issue?.should eq true
        client.pay.should_not be_a(PaytureAPI::Response)
      end
    end
  end

  context '#charge' do
    it 'should return Charged response' do
      #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/Charge/).to_return(:status => 200, :body => '<Charge Success="False" OrderId="" Amount="0" ErrCode="ORDER_NOT_FOUND" />')
      response = FutubankAPI::Client.charge({})
      response.response_code.should eq('ORDER_NOT_FOUND')
    end
  end

  context '#get_state' do
    it 'should return GetState response' do
      #stub_request(:get, /http\:\/\/sandbox.payture.com\/api\/GetState/).to_return(:status => 200, :body => '<GetState Success="True" Amount="60000" State="SomeState" Forwarded="False"/>')
      response = FutubankAPI::Client.get_state({})
      expect(response.ok?).to be true
      response.attributes["State"].should eq("SomeState")
    end
  end
end

