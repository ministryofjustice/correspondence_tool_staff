module Stoppable
  extend ActiveSupport::Concern

  def stoppable?
    !stopped? && !closed?
  end

  def restartable?
    stopped? && stopped_at.present?
  end
end
