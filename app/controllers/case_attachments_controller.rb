class CaseAttachmentsController < ApplicationController
  before_action :set_case, only: [:create, :new]
  # before_cation :set_type, only: [:new]
  # before_action :set_attachment, only: [:show, :edit, :update]
  before_action :set_s3_direct_post, only: [:new]

  def new
    @attachment = CaseAttachment.new type: 'response'
  end

  def create
    @attachment = CaseAttachment.new(case_attachment_params)
    @case.attachments << @attachment

    if @attachment.save
      puts "saved attachment: #{@attachment.inspect}"
      redirect_to case_path @case
    else
      puts "flubbed attachment: #{@attachment.inspect}"
      render :new
    end
  end

  private

  def case_attachment_params
    params.require(:case_attachment).permit(
      :type,
      :url
    )
  end

  def set_case
    @case = Case.find(params[:case_id])
  end

  def set_type
    @type = params[:type]
  end

  def set_s3_direct_post
    @s3_direct_post = CASE_UPLOADS_S3_BUCKET.presigned_post(
      key:                   "uploads/#{SecureRandom.uuid}/${filename}",
      success_action_status: '201',
      acl:                   'public-read'
    )
  end
end
