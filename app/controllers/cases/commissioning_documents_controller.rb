module Cases
  class CommissioningDocumentsController < ApplicationController
    before_action :set_case
    before_action :set_data_request_area
    before_action :set_commissioning_document

    def create
      @commissioning_document.template_name = create_params[:template_name].to_sym

      if @commissioning_document.valid?
        if FeatureSet.email_commissioning_document.enabled?
          @commissioning_document.save!
          redirect_to case_data_request_area_data_request_path(@case, @data_request_area, @data_request), notice: "Day 1 request document selected"
        else
          send_data(@commissioning_document.document,
                    filename: @commissioning_document.filename,
                    type: @commissioning_document.mime_type)
        end
      else
        render :new
      end
    end

    def update
      @commissioning_document.template_name = create_params[:template_name].to_sym

      if @commissioning_document.valid?
        @commissioning_document.save!
        @commissioning_document.remove_attachment
        redirect_to case_data_request_area_data_request_path(@case, @data_request_area, @data_request), notice: "Day 1 request document updated"
      else
        render :edit
      end
    end

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
      @data_request_area = @case.data_request_areas.find(params[:data_request_area_id])
    end

    def set_commissioning_document
      @commissioning_document = CommissioningDocument.find_or_initialize_by(data_request_area: @data_request_area)
    end

    def create_params
      if params[:commissioning_document]
        params.require(:commissioning_document).permit(:template_name, upload: [])
      else
        ActiveSupport::HashWithIndifferentAccess.new
      end
    end
  end
end
