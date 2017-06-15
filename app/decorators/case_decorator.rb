class CaseDecorator < Draper::Decorator
  delegate_all

  def who_its_with
    case current_state
    when 'closed'                 then ''
    when 'responded'              then managing_team.name
    when 'pending_dacu_clearance' then 'DACU - Disclosure'
    else
      responder_or_team
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

  def internal_deadline
    if object.requires_clearance?
      I18n.l(object.internal_deadline, format: :default)
    else
      ' '
    end
  end

  def external_deadline
    I18n.l(object.external_deadline, format: :default)
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

  private

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def responder_or_team
    if !responding_team.present?
      managing_team.name
    elsif responder.present? &&
          h.current_user.responding_teams.include?(responding_team)
      responder.full_name
    else
      responding_team.name
    end
  end
end

