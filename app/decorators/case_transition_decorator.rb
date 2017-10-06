class CaseTransitionDecorator < Draper::Decorator
  delegate_all

  def action_date
    object.created_at.strftime('%d %b %Y<br>%H:%M').html_safe
  end

  def user_name
    object.acting_user.full_name
  end

  def user_team
    object.acting_team.name
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
      "Assigned to #{object.target_team.name}"
    when 'reject_responder_assignment',
      'request_amends',
      'add_responses',
      'add_response_to_flagged_case',
      'upload_response_and_return_for_redraft',
      'upload_response_and_approve',
      'approve_and_bypass',
      'upload_response_approve_and_bypass'
        object.message
    when 'reassign_user'
      target_user = User.find(object.target_user_id)
      acting_user = User.find(object.acting_user_id)
      "#{ acting_user.full_name } re-assigned this case to <strong>#{ target_user.full_name }</strong>"
    end
  end
end
