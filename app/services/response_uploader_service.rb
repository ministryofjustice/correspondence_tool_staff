class ResponseUploaderService

  attr_reader :result

  # action_params is passed through from the flash on the upload page and can be:
  # * 'upload' - upload response but don't change state
  # * 'upload-flagged' - upload response to flagged case and transition to pending_dacu_clearance
  # * 'upload-approve' - approver uploads a response and approves
  # * 'upload-revert' - approer uploads a response and reverts to kilo for amendments
  #
  def initialize(kase, current_user, params, action_params)
    @case = kase
    @current_user = current_user
    @params = params
    @result = nil
    @action = action_params
  end

  def upload!
    if @params[:uploaded_files].blank?
      @result = :blank
    else
      process_files
    end
  end

  def seed!
    key = "#{@case.attachments_dir('responses')}/eon.pdf"
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(key)
    uploads_object.upload_file(File.join(Rails.root, 'spec', 'fixtures', 'eon.pdf'))
    @case.attachments << CaseAttachment.new(type: 'response', key: key)
    PdfMakerJob.perform_now(@case.attachments.first.id)
  end

  private

  def response_attachments
    @response_attachments ||= @params[:uploaded_files].reject(&:blank?).map do |uploads_key|
      move_uploaded_response(uploads_key)
      CaseAttachment.find_or_initialize_by(
        type: 'response',
        key: response_destination_key(uploads_key)
      )
    end
  end

  def process_files
    ActiveRecord::Base.transaction do
      @result = add_attachment_and_transition_state
    end
  end

  def add_attachment_and_transition_state
    if response_attachments.all?(&:valid?)
      response_attachments.select(&:persisted?).each(&:touch)
      @case.attachments << response_attachments
      transition_state(response_attachments)
      remove_leftover_upload_files
      Rails.logger.warn "QUEUEING PDF MAKER JOB"
      response_attachments.each { |ra| PdfMakerJob.perform_later(ra.id) }
      :ok
    else
      :error
    end
  end

  def transition_state(response_attachments)
    filenames = response_attachments.map(&:filename)
    case @action
    when 'upload'
      @case.state_machine.add_responses!(@current_user, @case.responding_team, filenames)
    when 'upload-flagged'
      @case.state_machine.add_response_to_flagged_case!(@current_user, @case.responding_team, filenames)
    when 'upload-approve'
      @case.state_machine.upload_response_and_approve!(
        @current_user,
        @case.approving_teams.with_user(@current_user).first,
        filenames
      )
    when 'upload-revert'
      @case.state_machine.upload_response_and_return_for_redraft!(
                           @current_user,
                           @case.approving_teams.with_user(@current_user).first,
                           filenames
      )
    else
      raise 'Unexpected action parameter'
    end
  end

  def move_uploaded_response(uploads_key)
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(uploads_key)
    uploads_object.move_to response_destination_path(uploads_key)
  end

  def response_destination_path(uploads_key)
    "#{Settings.case_uploads_s3_bucket}/#{response_destination_key(uploads_key)}"
  end

  def response_destination_key(uploads_key)
    "#{@case.attachments_dir('responses')}/#{File.basename(uploads_key)}"
  end

  def remove_leftover_upload_files
    prefix = "uploads/#{@case.id}"
    CASE_UPLOADS_S3_BUCKET.objects(prefix: prefix).each do |object|
      object.delete
    end
  end
end
