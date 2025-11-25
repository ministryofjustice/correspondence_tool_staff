module Cases
  class RestartTheClocksController < ApplicationController
    include SetupCase

    before_action :set_case, only: %i[new create]

    def new
      authorize @case, :can_restart_the_clock?

      @case = CaseRestartTheClockDecorator.decorate @case
    end

    def create
      authorize @case, :can_restart_the_clock?

      restart_the_clock_params = params[:case]

      restart_the_clock_date = begin
        Date.new(
          restart_the_clock_params[:restart_the_clock_date_yyyy].to_i,
          restart_the_clock_params[:restart_the_clock_date_mm].to_i,
          restart_the_clock_params[:restart_the_clock_date_dd].to_i,
        )
      rescue StandardError
        nil
      end

      service = CaseRestartTheClockService.new(
        current_user,
        @case,
        restart_the_clock_date
      )

      result = service.call

      case result
      when :ok
        flash[:notice] = "You have restarted the clock on this case. The deadlines have been updated."
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseRestartTheClockDecorator.decorate @case
        @case.restart_the_clock_date = restart_the_clock_params[:restart_the_clock_date]
        render :new
      else
        flash[:alert] = "Unable to restart the clock on this case."
        redirect_to case_path(@case.id)
      end
    end
  end
end
