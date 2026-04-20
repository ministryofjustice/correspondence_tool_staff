module Cases
  class CommissioningDocumentsController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area
    before_action :set_commissioning_document

    def download
      return unless @commissioning_document.persisted?

      send_data(@commissioning_document.document,
                filename: @commissioning_document.filename,
                type: @commissioning_document.mime_type)
    end

    def send_email
      service = CommissioningDocumentEmailService.new(
        data_request_area: @data_request_area,
        current_user:,
        commissioning_document: @commissioning_document,
      )
      service.send!

      redirect_to case_path(@case), flash: { notice: "Day 1 commissioning email sent" }
    end

  private

    def set_case
      @case = Case::Base.find(params[:case_id])
    end

    def set_data_request_area
      @data_request_area = @case.data_request_areas.find(params[:data_request_area_id]).decorate
    end

    def set_commissioning_document
      if @data_request_area.commissioning_document.present?
        @commissioning_document = @data_request_area.commissioning_document.decorate
      else
        redirect_to case_data_request_area_path(@case, @data_request_area), flash: { alert: I18n.t("cases.commissioning_documents.not_found") }
      end
    end
  end
end
