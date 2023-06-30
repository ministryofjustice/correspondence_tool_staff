module Steppable
  extend ActiveSupport::Concern

  included do
    attr_writer :current_step
  end

  def steps
    []
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

  def steps_are_completed?
    @current_step == steps.last
  end

  def get_next_step
    if current_step == steps.last
      current_step
    else
      steps[steps.index(current_step) + 1]
    end
  end

  def get_previous_step
    current_index = steps.index(current_step)
    current_index.positive? ? steps[current_index - 1] : nil
  end

  def valid_attributes?(params)
    params ||= ActionController::Parameters.new({}).permit!
    validate_method_name = "validate_#{current_step.tr('-', '_')}"
    if respond_to?(validate_method_name, params)
      send(validate_method_name, params)
    end
    object.valid_attributes?(params)
  end

  def process_params_after_step(params)
    params ||= ActionController::Parameters.new({}).permit!
    params_after_step_method_name = "params_after_step_#{current_step.tr('-', '_')}"
    if respond_to?(params_after_step_method_name, params)
      params = send(params_after_step_method_name, params)
    end
    params
  end
end
