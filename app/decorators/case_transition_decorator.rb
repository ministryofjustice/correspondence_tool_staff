class CaseTransitionDecorator < Draper::Decorator
  delegate_all

  def action_date
    object.created_at.strftime("%d %b %Y<br>%H:%M").html_safe
  end

  def user_name
    object.acting_user.full_name
  end

  def user_team
    object.acting_team.name
  end

  def event_and_detail
    "<strong>#{event_desc}</strong><br>#{details}".html_safe
  end

  def event_desc
    rejected_case_creation_event || description_for_event || event_name
  end

private

  def description_for_event
    specific_key_with_desc = "event.case/#{object.case.type_abbreviation.downcase}.#{object.event}__desc"
    default_key_with_desc = "event.#{object.event}_desc"
    I18n.t(specific_key_with_desc, default: nil) || I18n.t(default_key_with_desc, state: object.to_state.humanize, default: nil)
  end

  def event_name
    specific_key = "event.case/#{object.case.type_abbreviation.downcase}.#{object.event}"
    default_key = "event.#{object.event}"
    I18n.t(specific_key, default: I18n.t(default_key))
  end

  def rejected_case_creation_event
    # This method prevents the case history changing from "rejected case created" to "case created"
    # when a Case state is changed from "rejected" to another state
    if object.case.has_attribute?(:case_originally_rejected) && object.event == "create" && object.case.case_originally_rejected
      I18n.t("event.case/#{object.case.type_abbreviation.downcase}.rejected.#{object.event}")
    end
  end

  def event
    state_machine = object.case.state_machine
    state_machine.event_name(object.event)
  end

  def details
    case object.event
    when "assign_responder", "assign_to_new_team"
      "Assigned to #{object.target_team.name}"
    when "remove_linked_case"
      message_base_on_linked_case
    when "progress_for_clearance"
      "Progressed to #{object.target_team.name}"
    when "add_responses",
         "add_response_to_flagged_case",
         "approve_and_bypass",
         "extend_for_pit",
         "extend_sar_deadline",
         "reject_responder_assignment",
         "request_amends",
         "upload_response_and_return_for_redraft",
         "upload_response_and_approve",
         "upload_response_approve_and_bypass",
         "validate_rejected_case"
      object.message
    when "assign_to_team_member"
      construct_message_for_assign_to_team_member
    when "reassign_user"
      construct_message_for_reassign_user
    else
      object&.message
    end
  end

  def construct_message_for_assign_to_team_member
    target_user = User.find(object.target_user_id)
    acting_user = User.find(object.acting_user_id)
    if target_user == acting_user
      "Self-assigned this case to <strong>#{target_user.full_name}</strong>"
    else
      "#{acting_user.full_name} assigned this case to <strong>#{target_user.full_name}</strong>"
    end
  end

  def construct_message_for_reassign_user
    target_user = User.find(object.target_user_id)
    acting_user = User.find(object.acting_user_id)
    "#{acting_user.full_name} re-assigned this case to <strong>#{target_user.full_name}</strong>"
  end

  def message_base_on_linked_case
    if Case::Base.exists?(object.linked_case_id)
      "Removed the link to <strong>#{Case::Base.find(object.linked_case_id).number}</strong>"
    else
      "Removed the link to case_id: <strong>#{object.linked_case_id}</strong>.
      (NOTE: This case was deleted after the case link was removed.)"
    end
  end
end
