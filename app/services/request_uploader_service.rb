class RequestUploaderService
  include UploaderService

  def initialize(kase, current_user, uploaded_files)
    @case = kase
    @current_user = current_user
    @uploaded_files = uploaded_files
    @upload_group = create_upload_group
    @result = nil
    @type = :request
  end

  def upload!
    if @uploaded_files.blank?
      @result = :blank
    else
      attachments = process_files(@uploaded_files, @type)
      transition_state(attachments)
      @result = :ok
      attachments
    end
  rescue => err
    Rails.logger.error("Error processing uploaded files: #{err.message}")
    @result = :error
  end

  private

  def transition_state(attachments)
    filenames = attachments.map(&:filename)
    @case.state_machine.add_request_attachments!(
      @current_user,
      @current_user.managing_teams.first,
      filenames
    )
  end
end
