module Cases
  class AttachmentsController < ApplicationController
    include CaseAttachmentParams

    before_action :set_case,       only: [:new, :create, :destroy, :download, :show]
    before_action :set_attachment, only: [:destroy, :download, :show]

    def download
      redirect_to @attachment.temporary_url
    end

    def show
      tmpfile_path = download_to_tmpfile(@attachment.preview_key)

      mime_type = Rack::Mime.mime_type(File.extname @attachment.preview_key)
      send_file tmpfile_path, type: mime_type, disposition: 'inline'
    end

    def destroy
      authorize @case, :can_remove_attachment?

      @case.remove_response(current_user, @attachment)

      if @case.attachments.empty? && request.format == :js
        render js: "window.location = '#{case_path(@case)}'"
      else
        respond_to do |format|
          format.js
          format.html { redirect_to case_path(@case) }
        end
      end
    end

    def new
      authorize @case, :can_upload_request_attachment?
      @s3_direct_post = S3Uploader.for(@case, 'requests')
    end 

    def create 
      authorize @case, :can_upload_request_attachment?
      service = RequestUploaderService.new(
        kase: @case,
        current_user: current_user,
        uploaded_files: create_params[:uploaded_request_files],
        upload_comment: create_params[:upload_comment]
      )
      service.upload!

      case service.result
      when :ok
        flash[:notice] = t('notices.request_uploaded')
        redirect_to case_path @case
      when :blank
        flash[:alert] = t('notices.no_request_uploaded')
        redirect_to case_path @case
      else 
        @s3_direct_post = S3Uploader.for(@case, 'requests')
        @case = @case.decorate
        flash.now[:alert] = service.error_message
        render :new
      end

    end 

    private

    def download_to_tmpfile(key)
      extname = File.extname(key)
      tmpfile = Tempfile.new(['orig', extname])
      tmpfile.close
      attachment_object = CASE_UPLOADS_S3_BUCKET.object(key)
      attachment_object.get(response_target: tmpfile.path)
      tmpfile.path
    end

    def set_attachment
      @attachment = @case.attachments.find(params[:id])
    end

    def set_case
      @case = Case::Base.find(params[:case_id])
    end
  end
end
