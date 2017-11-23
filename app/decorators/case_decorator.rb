class CaseDecorator < Draper::Decorator
  delegate_all

  # if the case is with a responding team and the current user is a responder
  # in that team, display the name of the specific user it's with instead of
  # the team name
  #
  def who_its_with
    tandu = object.current_team_and_user
    if tandu.user.present? && h.current_user.responding_teams.include?(tandu.team)
      tandu.user.full_name
    else
      tandu.team&.name
    end
  end

  def time_taken
    business_days = received_date.business_days_until(date_responded)
    I18n.t('common.case.time_taken_result', count: business_days)
  end

  def timeliness
    if within_external_deadline?
      I18n.t('common.case.answered_in_time')
    else
      I18n.t('common.case.answered_late')
    end
  end

  # we only display the internal deadline for flagged cases
  def internal_deadline
    if object.flagged?
      I18n.l(object.internal_deadline, format: :default)
    else
      ' '
    end
  end

   # we only display the marker for flagged cases
  def trigger_case_marker
    if object.flagged?
      h.content_tag :div, class: 'foi-trigger' do
        h.content_tag(:span, 'This is a ', class: 'visually-hidden') +
          "Trigger" +
          h.content_tag(:span, ' case', class: 'visually-hidden' )
      end
    else
      ' '
    end
  end

  def external_deadline
    I18n.l(object.external_deadline, format: :default)
  end

  def escalation_deadline
    I18n.l(object.escalation_deadline, format: :default)
  end

  def error_summary_message
    "#{h.pluralize(errors.count, I18n.t('common.error'))} #{ I18n.t('common.summary_error')}"
  end

  def requester_type
    object.requester_type.humanize
  end

  def requester_name_and_type
    "#{object.name} | #{requester_type}"
  end

  def message_extract(num_chars = 350)
    if object.message.size < num_chars
      [object.message]
    else
      [object.message[0..num_chars-1] ,  object.message[num_chars..-1]]
    end
  end

  def shortened_message
    (part1,part2) = self.message_extract

    if part2.nil?
      object.message
    else
      "#{part1}..."
    end
  end

  def status
    if current_state != 'closed'
      I18n.t("state.#{current_state}")
    else
      I18n.t("state.#{current_state}_status")
    end
  end

  def date_sent_to_requester
    I18n.l(object.date_responded, format: :default)
  end

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def responding_team_lead_name
    object.responding_team&.team_lead
  end

  def default_clearance_team_name
    object.default_team_service.default_clearance_team.name
  end

  def default_clearance_approver
    object.approver_assignment_for(object.default_team_service.approving_team)&.user&.full_name
  end

  def message_notification_visible?(user)
    tracker = transition_tracker_for_user(user)
    if tracker.present?
      !tracker.is_up_to_date?
    else
      object.message_transitions.any?
    end
  end

  def pretty_type
    case type
    when 'FoiComplianceReview'
      'FOI - Internal review for compliance'
    when 'FoiTimelinessReview'
      'FOI - Internal review for timeliness'
    when "Case"
      'FOI'
    else
      raise 'type does not exist'
    end
  end
end
