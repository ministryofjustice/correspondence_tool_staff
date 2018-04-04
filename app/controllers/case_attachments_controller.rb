class CaseAttachmentsController < ApplicationController
  before_action :set_case,       only: [:create_from_s3,
                                        :destroy,
                                        :download,
                                        :preview,
                                        :show]
  before_action :set_attachment, only: [:destroy, :download, :preview, :show]

  def create_from_s3
    authorize @case, :can_add_attachment?

    attachment = CaseAttachment.new(create_params)
    attachment.case = @case
    attachment.save
    VirusScanJob.perform_later(attachment.id)

    redirect_to case_attachment_path(case_id: @case.id, id: attachment.id)
  end

  def download
    redirect_to @attachment.temporary_url
  end

  def preview
    tmpfile_path = download_to_tmpfile(@attachment.preview_key)
    send_file tmpfile_path, type: File.mime_type?(@attachment.preview_key), disposition: 'inline'
  end

  def show
    render json: @attachment.to_json
  end

  def destroy
    authorize @case, :can_remove_attachment?

    @case.remove_response(current_user, @attachment)

    if @case.attachments.empty? && request.format == :js
      render :js => "window.location = '#{case_path(@case)}'"
    else
      respond_to do |format|
        format.js
        format.html { redirect_to case_path(@case) }
      end
    end
  end

  private

  def create_params
    params.require(:case_attachment).permit(:key, :type)
  end

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
