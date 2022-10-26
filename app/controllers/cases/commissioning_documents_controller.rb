module Cases
  class CommissioningDocumentsController < ApplicationController
    before_action :set_case
    before_action :set_data_request

    def new; end

    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request
      @data_request = DataRequest.find(params[:data_request_id])
    end
  end
end
