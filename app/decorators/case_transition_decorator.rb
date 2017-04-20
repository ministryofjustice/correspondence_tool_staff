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
    when 'respond'
      'Marked as responded'
    end
  end
end
