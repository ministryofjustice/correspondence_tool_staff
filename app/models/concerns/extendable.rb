module Extendable
  extend ActiveSupport::Concern

  def deadline_extendable?
    max_allowed_deadline_date > external_deadline
  end

  def initial_deadline
    sar_extensions = transitions
      .where(event: "extend_sar_deadline")
      .order(:id)

    if sar_extensions.any?
      sar_extensions.first.original_final_deadline
    else
      external_deadline
    end
  end

  def extend_deadline!(new_deadline, new_extended_times)
    update!(
      external_deadline: new_deadline,
      deadline_extended: true,
      extended_times: new_extended_times,
    )
  end

  def reset_deadline!
    if restarted_at.present?
      old_deadline = last_restart_the_clock_transition&.details&.fetch("new_external_deadline", nil)&.to_date
    end

    old_deadline ||= @deadline_calculator.external_deadline

    update!(
      external_deadline: old_deadline,
      deadline_extended: false,
      extended_times: 0,
    )
  end

  # The deadlines are all calculated based on the date case is received or last restart
  def max_allowed_deadline_date
    @deadline_calculator.max_allowed_deadline_date(max_time_limit) do
      if restarted_at.present?
        old_deadline = last_restart_the_clock_transition&.details&.fetch("new_external_deadline", nil)&.to_date
        old_deadline || received_date
      else
        received_date
      end
    end
  end

  def extension_time_limit
    correspondence_type.extension_time_limit || Settings.sar_extension_default_limit
  end

  def extension_time_default
    correspondence_type.extension_time_default || Settings.sar_extension_default_time_gap
  end

  def max_time_limit
    correspondence_type.extension_time_limit || Settings.sar_extension_default_limit
  end

  def sar_extensions
    transitions.where(event: "extend_sar_deadline").order(:id)
  end
end
