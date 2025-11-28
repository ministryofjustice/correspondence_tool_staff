module Cases
  class StopTheClocksController < ApplicationController
    include SetupCase

    before_action :set_case, only: %i[new create]

    def new
      authorize @case, :can_stop_the_clock?

      @case = CaseStopTheClockDecorator.decorate @case
    end

    def create
      authorize @case, :can_stop_the_clock?

      stop_the_clock_params = params[:case]

      service = CaseStopTheClockService.new(
        current_user, @case, stop_the_clock_params
      )
      result = service.call

      case result
      when :ok
        flash[:notice] = "You have stopped the clock on this case."
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseStopTheClockDecorator.decorate @case
        @case.stop_the_clock_categories = stop_the_clock_params[:stop_the_clock_categories]
        @case.stop_the_clock_reason = stop_the_clock_params[:stop_the_clock_reason]
        @case.stop_the_clock_date_yyyy = stop_the_clock_params[:stop_the_clock_date_yyyy]
        @case.stop_the_clock_date_mm = stop_the_clock_params[:stop_the_clock_date_mm]
        @case.stop_the_clock_date_dd = stop_the_clock_params[:stop_the_clock_date_dd]

        render :new
      else
        flash[:alert] = "Unable to stop the clock on this case."
        redirect_to case_path(@case.id)
      end
    end
  end
end
