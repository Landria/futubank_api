module FutubankAPI
  class Response

    SUCCESS_VALUE = ['True', '3DS']

    def initialize response
      @response = response
      @body = response.body.to_json
    end

    def ok?
      !error?
    end

    def connectivity_issue?
      parsing_errors?
    end

    def duplicate_order_id?
      response_code == 'DUPLICATE_ORDER_ID'
    end

    def message
      if @body.errors.empty?
        response_code
      else
        @body.errors.join
      end
    end

    def error?
      if parsing_errors?
        true
      else
        !SUCCESS_VALUE.include? response_code
      end
    end

    def three_ds?
      ok? && response_code == '3DS'
    end

    def three_ds_attributes
      if three_ds?
        { url: attributes['ACSUrl'],
          pa_req: attributes['PaReq'],
          md: attributes['ThreeDSKey'] }
      else
        nil
      end
    end

    def response_code
      if SUCCESS_VALUE.include? attributes['Success']
        attributes['Success']
      else
        attributes['ErrCode']
      end
    end

    # parse all attributes from response to Hash
    # example out of this method:
    #   {"success" => "True", "OrderId" => "-1", ...  }
    #
    def attributes
      @attributes ||= @body.children[0]
        .attributes
        .inject({}){ |h,attr| h[attr[0]]=attr[1].value; h }
    end

    private

    def parsing_errors?
      !@body.errors.empty?
    end
  end
end
