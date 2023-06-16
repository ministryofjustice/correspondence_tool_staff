class StateSelector
  extend ActiveModel::Naming
  include ActiveModel::Model

  attr_accessor :selected_states

  def initialize(params)
    @available_states = ConfigurableStateMachine::Machine.states.map(&:to_sym)
    @selected_states = []
    if params[:state_selector]
      set_states_from_form_input(params)
    elsif params[:states]
      set_states_from_url(params)
    end
  end

  def method_missing(meth, *params)
    if meth.in?(@available_states)
      meth.in?(@selected_states)
    else
      super
    end
  end

  def respond_to_missing?(meth, include_private: false)
    meth.in?(@available_states) || super
  end

  def states_for_url
    @selected_states.uniq.join(",")
  end

private

  def set_states_from_form_input(params)
    params[:state_selector].each { |state, set| @selected_states << state.to_sym if set == "1" }
  end

  def set_states_from_url(params)
    params[:states].split(",").each { |state| @selected_states << state.to_sym }
  end
end
