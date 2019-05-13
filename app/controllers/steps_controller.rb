class StepsController < ApplicationController
  include Steppable 
  STEPS = [:step1, :step2, :step3].freeze

  def new
    @case = Case::FOI::Standard.new
    current_step = params[:step]
  end

  private

end
