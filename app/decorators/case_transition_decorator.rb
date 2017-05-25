class CaseTransitionDecorator < Draper::Decorator
  delegate_all

  def action_date
    object.created_at.strftime('%d %b %Y<br>%H:%M').html_safe
  end

  def user_name
    object.user.full_name
  end

  def event_and_detail
    "<strong>#{event}</strong><br>#{details}".html_safe
  end

  private
  def event
    CaseStateMachine.event_name(object.event)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def details
    case object.event
    when 'assign_responder'
      "Assigned to #{object.responding_team.name}"
    when 'reject_responder_assignment'
      object.message
    when 'accept_responder_assignment'
      "Accepted for response"
    when 'add_responses'
      "#{h.pluralize(object.filenames.size, 'file')} added"
    when 'add_response_to_flagged_case'
      "#{h.pluralize(object.filenames.size, 'file')} added<br/>Case is now Pending clearance with DACU disclosure team"
    when 'respond'
      'Marked as responded'
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
