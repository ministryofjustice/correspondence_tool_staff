class CaseAttachmentsController < ApplicationController
  before_action :set_case,       only: [:create,
                                        :destroy,
                                        :download,
                                        :preview,
                                        :show]
  before_action :set_attachment, only: [:destroy, :download, :preview, :show]

  def create
    authorize @case, :can_add_attachment?

    attachment = CaseAttachment.create!(create_params.merge(case: @case))
    VirusScanJob.perform_later(attachment.id)

    render json: {path: case_attachment_path(case_id: @case.id, id: attachment.id)},
           status: :created, location: case_attachment_path(case_id: @case.id, id: attachment.id )
    # redirect_to case_attachment_path(case_id: @case.id, id: attachment.id )
  end

  def check_scan
    attachment_key = params[:key]
    CASE_UPLOADS_S3_BUCKET.object(attachment_key)
    client = CASE_UPLOADS_S3_BUCKET.client
    tag_sets = client.get_object_tagging(bucket: CASE_UPLOADS_S3_BUCKET.name,
                                         key: attachment_key).to_h
    tag = tag_sets[:tag_set].find { |tags| tags[:key] == 'moj-virus-scan' }
    tag_value = tag ? tag[:value] : 'PENDING'
    render json: { virus_scan_result: tag_value }
  end

  def download
    redirect_to @attachment.temporary_url
  end

  def preview
    tmpfile_path = download_to_tmpfile(@attachment.preview_key)
    send_file tmpfile_path, type: File.mime_type?(@attachment.preview_key), disposition: 'inline'
  end

  def show
    render json: @attachment
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

  # def set_correspondence_type(type)
  #   @correspondence_type = CorrespondenceType.find_by_abbreviation(type.upcase)
  #   @correspondence_type_key = type
  # end
end
