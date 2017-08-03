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
    when 'reassign_user'
      target_user = User.find(object.target_user_id)
      acting_user = User.find(object.acting_user_id)
      "#{ acting_user.full_name } re-assigned this case to <strong>#{ target_user.full_name }</strong>"
    end
  end
end
