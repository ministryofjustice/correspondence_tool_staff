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
      existing_attachment = @commissioning_document.attachment
      @commissioning_document.attachment_id = nil

      if @commissioning_document.valid?
        existing_attachment&.destroy!
        @commissioning_document.save
        redirect_to case_data_request_path(@case, @data_request), notice: "Document was updated"
      else
        render :edit
      end
    end

    def download
      return unless @commissioning_document.persisted?

      document = @commissioning_document.stored? ? @commissioning_document.attachment.download : @commissioning_document.document

      send_data(document,
        filename: @commissioning_document.filename,
        type: @commissioning_document.mime_type,
      )
    end

    def replace
      @s3_direct_post = S3Uploader.for(@case, 'commissioning_document')
    end

    def upload
      @params = params
      service = CommissioningDocumentUploaderService.new(
        kase: @case,
        commissioning_document: @commissioning_document,
        current_user: current_user,
        uploaded_file: create_params[:upload]
      )
      service.upload!

      case service.result
      when :ok
        flash[:notice] = t('notices.commissioning_document_uploaded')
        redirect_to case_data_request_path(@case, @data_request)
      when :blank
        flash[:alert] = t('notices.no_commissioning_document_uploaded')
        redirect_to case_data_request_path(@case, @data_request)
      else
        @s3_direct_post = S3Uploader.for(@case, 'commissioning_document')
        flash.now[:alert] = service.error_message
        render :replace
      end
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
      params.require(:commissioning_document).permit(:template_name, upload: [])
    end
  end
end
