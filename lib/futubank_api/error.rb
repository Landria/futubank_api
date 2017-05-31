module FutubankAPI
  module Error
    def ok?; false end
    def connectivity_issue?; true end
    def response_code; self.message end
  end
end