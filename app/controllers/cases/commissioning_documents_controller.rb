module Cases
  class CommissioningDocumentsController < ApplicationController
    before_action :set_case
    before_action :set_data_request
    before_action :set_commissioning_document

    def create
      @commissioning_document.template_name = create_params[:template_name].to_sym

      if @commissioning_document.valid?
        @commissioning_document.save
        redirect_to case_data_request_path(@case, @data_request), notice: "Document was created"
      else
        render :new
      end
    end

    def update
      @commissioning_document.template_name = create_params[:template_name].to_sym

      if @commissioning_document.valid?
        @commissioning_document.save
        redirect_to case_data_request_path(@case, @data_request), notice: "Document was updated"
      else
        render :edit
      end
    end

    def download
      return unless @commissioning_document.persisted?

      send_data(@commissioning_document.document,
        filename: @commissioning_document.filename,
        type: @commissioning_document.mime_type,
      )
    end

    private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request
      @data_request = DataRequest.find(params[:data_request_id])
    end

    def set_commissioning_document
      @commissioning_document = CommissioningDocument.find_or_initialize_by(data_request: @data_request)
    end

    def create_params
      params.require(:commissioning_document).permit(:template_name)
    end
  end
end
