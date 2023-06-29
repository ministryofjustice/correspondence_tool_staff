class CaseAttachmentUploadGroupSeeder
  RESPONSE_EVENTS = %w[
    add_responses
    add_response_to_flagged_case
    upload_response_and_approve
  ].freeze

  def initialize
    @transitions = CaseTransition.where(event: RESPONSE_EVENTS)
  end

  def run
    @transitions.each { |t| process_transition(t) }
  end

private

  def process_transition(transition)
    transition.filenames.each do |filename|
      attachments = CaseAttachment.where("case_id = ? and key like ?", transition.case_id, "%#{filename}")
      raise "Too many matching attachments for case_id #{transition.case_id} and key #{key}" if attachments.size > 1

      attachment = attachments.first
      if attachment
        upload_group = transition.created_at.strftime("%Y%m%d%H%M%S")
        attachment.update!(upload_group:, user_id: transition.user_id)
      end
    end
  end
end
