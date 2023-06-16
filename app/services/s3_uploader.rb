class S3Uploader
  def initialize(kase, user)
    @case = kase
    @user = user
    @upload_group = create_upload_group
  end

  def self.s3_direct_post_for_case(kase, type)
    uploads_key = "uploads/#{kase.uploads_dir(type)}/${filename}"
    CASE_UPLOADS_S3_BUCKET.presigned_post(
      key: uploads_key,
      success_action_status: "201",
    )
  end

  def self.for(kase, upload_type)
    s3_direct_post_for_case(kase, upload_type)
  end

  def self.id_for_case(kase)
    if kase.persisted?
      kase.id
    else
      SecureRandom.urlsafe_base64
    end
  end

  def upload_file_to_case(type, file, filename)
    key = destination_key(filename, type)
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(key)
    uploads_object.upload_file(file)

    attachment = CaseAttachment.create!(
      type: type.to_s,
      key:,
      upload_group: @upload_group,
      user_id: @user.id,
    )
    @case.attachments << attachment
    attachment
  end

  def process_files(uploaded_files, type)
    ActiveRecord::Base.transaction do
      add_attachments(uploaded_files, type)
    end
  end

  def add_file_to_case(filepath, type)
    # This method is being used by the cts script which only wants to upload
    # the file to S3, but not to run PdfMakerJob job, it'll run it itself now.
    filename = File.basename(filepath)
    key = "#{@case.attachments_dir(type.to_s, @upload_group)}/#{filename}"
    attachment = CaseAttachment.create!(
      type: type.to_s,
      key: destination_key(filepath, type),
      upload_group: @upload_group,
      user_id: @user.id,
    )
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(key)
    uploads_object.upload_file(filepath)
    @case.attachments << attachment
  end

private

  def add_attachments(uploaded_files, type)
    attachments = create_attachments(uploaded_files, type)

    # TODO: (Mohammed Seedat): this block of code is not necessary
    # because `create_attachments` can throw an exception on
    # CaseAttachment.create! This block of code runs during
    # the web-request before any jobs are added to a jobs queue
    unless attachments.all?(&:valid?)
      attachments.reject(&:valid?).each do |attachment|
        Rails.logger.error "invalid attachment for case #{@case.id}: #{attachment}"
      end
      raise "Cannot add invalid attachments to case."
    end

    @case.attachments << attachments

    remove_leftover_upload_files
    make_pdfs(attachments)
    attachments
  end

  def transition_state(_attachments)
    raise "Please define the 'transition_state' method in your service."
  end

  def create_attachments(uploaded_files, type)
    @attachments ||= uploaded_files.compact_blank.map do |uploads_key|
      move_uploaded_file(uploads_key, type)
      CaseAttachment.create!(
        type: type.to_s,
        key: destination_key(uploads_key, type),
        upload_group: @upload_group,
        user_id: @user.id,
      )
    end
  end

  def type_to_path(type)
    case type
    when :response then "responses"
    when :request  then "requests"
    when :ico_decision then "ico_decision"
    when :commissioning_document then "commissioning_document"
    else
      raise "unknown file type '#{type}'"
    end
  end

  def move_uploaded_file(uploads_key, type)
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(uploads_key)
    path = destination_path(uploads_key, type)
    uploads_object.move_to path
  end

  def destination_path(uploads_key, type)
    "#{Settings.case_uploads_s3_bucket}/#{destination_key(uploads_key, type)}"
  end

  def destination_key(uploads_key, type)
    attachments_dir = @case.attachments_dir(type_to_path(type), @upload_group)
    filename = File.basename(uploads_key)
    "#{attachments_dir}/#{filename}"
  end

  def remove_leftover_upload_files
    prefix = "uploads/#{@case.id}"
    CASE_UPLOADS_S3_BUCKET.objects(prefix:).each(&:delete)
  end

  def create_upload_group
    Time.zone.now.strftime("%Y%m%d%H%M%S")
  end

  def make_pdfs(attachments)
    needs_conversion = attachments.reject(&:commissioning_document?)
    return if needs_conversion.empty?

    Rails.logger.warn(
      "Queueing PDF maker job for attachments: #{needs_conversion.map { |a| "#{a.id}:#{a.key}" }.join(', ')}",
    )
    needs_conversion.each { |ra| PdfMakerJob.perform_later(ra.id) }
  end
end
