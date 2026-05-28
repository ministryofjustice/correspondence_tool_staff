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
      external_deadline: calculate_old_deadline,
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

  def calculate_old_deadline
    if restarted_at.present?
      calculate_old_deadline = last_restart_the_clock_transition&.details&.fetch("new_external_deadline", nil)&.to_date
    end

    calculate_old_deadline || @deadline_calculator.external_deadline
  end
end
