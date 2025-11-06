module Cases
  class StopTheClocksController < ApplicationController
    include SetupCase

    before_action :set_case, only: %i[new create]

    def new
      authorize @case, :stop_the_clock?

      @case = CaseStopTheClockDecorator.decorate @case
    end

    def create
      authorize @case, :stop_the_clock?

      stop_the_clock_params = params[:case]

      service = CaseStopTheClockService.new current_user,
                                            @case,
                                            stop_the_clock_params[:stop_reason]
      result = service.call

      case result
      when :ok
        flash[:notice] = "Case stopped temporarily until resumed"
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseStopTheClockDecorator.decorate @case
        @case.stop_reason = stop_the_clock_params[:stop_reason]
        render :new
      else
        flash[:alert] = "Unable to perform Stop the clock on case #{@case.number}"
        redirect_to case_path(@case.id)
      end
    end

  end
end
