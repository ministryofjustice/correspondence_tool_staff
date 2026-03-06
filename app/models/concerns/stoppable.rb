module Stoppable
  extend ActiveSupport::Concern

  included do
    attr_reader :stop_the_clock_date, :stop_the_clock_categories, :stop_the_clock_reason, :restart_the_clock_date
  end

  def stoppable?
    !stopped? && !closed?
  end

  def restartable?
    stopped? && stopped_at.present?
  end

  def stopped_at
    @stopped_at ||= last_stop_the_clock_transition&.details&.fetch("stop_the_clock_date")&.to_date
  end

  def restarted_at
    @restarted_at ||= last_restart_the_clock_transition&.details&.fetch("restart_the_clock_date")&.to_date
  end

  def last_stop_the_clock_transition
    @last_stop_the_clock_transition ||= transitions.where(event: "stop_the_clock").order(id: :desc).first
  end

  def last_restart_the_clock_transition
    @last_restart_the_clock_transition ||= transitions.where(event: "restart_the_clock").order(id: :desc).first
  end

  def prolonged_stop?
    @prolonged_stop ||= stopped? && stopped_at.present? && ((Time.zone.today - stopped_at).to_i > Settings.auto_close_stopped_threshold)
  end

  # Calculate the total time stopped across all stop/restart transitions for a case
  def total_time_stopped
    @total_time_stopped ||= begin
      events = transitions.where(event: %w[stop_the_clock restart_the_clock]).order(id: :asc)
      last_stop_date = nil

      return 0 unless events.any?

      events.sum do |event|
        case event.event
        when "stop_the_clock"
          last_stop_date = event.details["stop_the_clock_date"].to_date
          0
        when "restart_the_clock"
          if last_stop_date.present?
            days = (event.details["restart_the_clock_date"].to_date - last_stop_date).to_i
            last_stop_date = nil
            days
          else
            0
          end
        end
      end
    end
  end
end
