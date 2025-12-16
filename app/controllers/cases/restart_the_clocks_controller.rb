module Cases
  class RestartTheClocksController < ApplicationController
    include SetupCase

    before_action :set_case, only: %i[new create]

    def new
      authorize @case, :can_restart_the_clock?

      @case = CaseRestartTheClockDecorator.build(@case)
    end

    def create
      authorize @case, :can_restart_the_clock?

      restart_the_clock_params = params[:case]

      service = CaseRestartTheClockService.new(current_user, @case, restart_the_clock_params)
      result = service.call

      case result
      when :ok
        flash[:notice] = I18n.t("cases.restart_the_clocks.create.success")
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseRestartTheClockDecorator.build(@case, restart_the_clock_params)
        render :new
      when :last_working_state_missing
        flash[:alert] = I18n.t("cases.restart_the_clocks.create.last_working_state_missing")
        redirect_to case_path(@case.id)
      else
        flash[:alert] = I18n.t("cases.restart_the_clocks.create.failure")
        redirect_to case_path(@case.id)
      end
    end
  end
end
