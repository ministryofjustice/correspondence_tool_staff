module Extendable
  extend ActiveSupport::Concern

  def deadline_extendable?
    months_extended.to_i < extension_time_limit
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

  def extend_deadline!(new_deadline, new_months_extended)
    update!(
      external_deadline: new_deadline,
      deadline_extended: true,
      months_extended: new_months_extended,
    )
  end

  def reset_deadline!
    update!(
      external_deadline: recalculate_deadline_without_extensions,
      deadline_extended: false,
      months_extended: 0,
    )
  end

  def max_time_limit
    correspondence_type.extension_time_limit || Settings.sar_extension_default_limit
  end

  alias_method :extension_time_limit, :max_time_limit

  def extension_time_default
    correspondence_type.extension_time_default || Settings.sar_extension_default_time_gap
  end

  def sar_extensions
    transitions.where(event: "extend_sar_deadline").order(:id)
  end

  def active_extension?
    transitions.where(event: %w[extend_sar_deadline remove_sar_deadline_extension]).order(id: :desc).map(&:event).first == "extend_sar_deadline"
  end

  # Re-calculates the deadline by replaying all stopped/paused days on top of the original deadline
  def recalculate_deadline_without_extensions
    stopped_days_total = respond_to?(:total_days_stopped) ? total_days_stopped : 0

    @deadline_calculator.external_deadline + stopped_days_total.days
  end
end
