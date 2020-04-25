module Steppable
  extend ActiveSupport::Concern

  included do
    attr_writer :current_step
  end

  def current_step
    @current_step ||= steps.first
  end

  def next_step
    self.current_step = get_next_step
  end

  def previous_step
    self.current_step = get_previous_step
  end

  def get_next_step
    steps[steps.index(current_step) + 1]
  end

  def get_previous_step
    current_index = steps.index(current_step)
    current_index > 0 ? steps[current_index - 1] : nil
  end
end
