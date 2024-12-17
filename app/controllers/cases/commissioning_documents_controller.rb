module Cases
  class CommissioningDocumentsController < ApplicationController
    before_action :set_case
    before_action :set_data_request
    before_action :set_commissioning_document

    def create
      @commissioning_document.template_name = create_params[:template_name].to_sym

      if @commissioning_document.valid?
        if FeatureSet.email_commissioning_document.enabled?
          @commissioning_document.save!
          redirect_to case_data_request_path(@case, @data_request), notice: "Day 1 request document selected"
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
        redirect_to case_data_request_path(@case, @data_request), notice: "Day 1 request document updated"
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

    def replace
      @s3_direct_post = S3Uploader.for(@case, "commissioning_document")
    end

    def upload
      @params = params
      service = CommissioningDocumentUploaderService.new(
        kase: @case,
        commissioning_document: @commissioning_document,
        current_user:,
        uploaded_file: create_params[:upload],
      )
      service.upload!

      case service.result
      when :ok
        flash[:notice] = t("notices.commissioning_document_uploaded")
        redirect_to case_data_request_path(@case, @data_request)
      when :blank
        flash[:alert] = t("notices.no_commissioning_document_uploaded")
        redirect_to case_data_request_path(@case, @data_request)
      else
        @s3_direct_post = S3Uploader.for(@case, "commissioning_document")
        flash.now[:alert] = service.error_message
        render :replace
      end
    end

    def send_email
      service = CommissioningDocumentEmailService.new(
        data_request: @data_request,
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

    def set_data_request
      @data_request = DataRequest.find(params[:data_request_id])
    end

    def set_commissioning_document
      @commissioning_document = CommissioningDocument.find_or_initialize_by(data_request: @data_request)
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
