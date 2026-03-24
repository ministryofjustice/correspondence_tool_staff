module Stoppable
  extend ActiveSupport::Concern

  included do
    attr_reader :stop_the_clock_date, :stop_the_clock_categories, :stop_the_clock_reason
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
end
