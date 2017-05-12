class CaseAttachmentsController < ApplicationController
  before_action :set_case,       only: [:destroy, :download, :show]
  before_action :set_attachment, only: [:destroy, :download, :show]

  def download
    redirect_to @attachment.temporary_url
  end

  def show
    tmpfile_path = download_to_tmpfile(@attachment.preview_key)
    send_file tmpfile_path, type: File.mime_type?(@attachment.preview_key), disposition: 'inline'
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
    @case = Case.find(params[:case_id])
  end
end
