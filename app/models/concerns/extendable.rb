module Extendable
  extend ActiveSupport::Concern

  # Standard and Offender SARs may only be extended once, by a single fixed
  # period (see CorrespondenceType#extension_fixed_period). Other extendable
  # types (e.g. SAR Internal Review) retain the legacy behaviour of multiple
  # extensions up to a cumulative limit.
  def fixed_extension?
    extension_fixed_period.present?
  end

  def extension_fixed_period
    correspondence_type.extension_fixed_period
  end

  def deadline_extendable?
    if fixed_extension?
      !deadline_extended?
    else
      months_extended.to_i < extension_time_limit
    end
  end

  # The external deadline that would apply if the case were extended now.
  # Defaults to the fixed extension period; callers (e.g. the extension service)
  # may pass the submitted period explicitly.
  def new_extension_deadline(extend_by = extension_fixed_period)
    if try(:restarted_at).present?
      deadline_calculator.extension_deadline(extend_by) { external_deadline }
    else
      deadline_calculator.extension_deadline((months_extended || 0) + extend_by)
    end
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

    @deadline_calculator.closest_working_day_after(stopped_days_total, @deadline_calculator.external_deadline)
  end
end
