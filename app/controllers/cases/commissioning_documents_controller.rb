module Cases
  class CommissioningDocumentsController < ApplicationController
    before_action :set_case
    before_action :set_data_request

    def new
      @commissioning_document = CommissioningDocument.new(data_request: @data_request)
    end

    def create
      service = CommissioningDocumentTemplateService.new(
        data_request: @data_request,
        template_type: create_params[:template].to_sym,
      )

      service.call

      case service.result
      when :ok
        send_data service.document, filename: service.filename, type: service.mime_type
      when :error
        flash[:alert] = t('.error')
        redirect_to new_case_data_request_commissioning_document_path(@case, @data_request)
      end
    end

    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request
      @data_request = DataRequest.find(params[:data_request_id])
    end

    def create_params
      params.require(:commissioning_document).permit(:template)
    end
  end
end
