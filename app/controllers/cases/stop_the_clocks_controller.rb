module Cases
  class StopTheClocksController < ApplicationController
    include SetupCase

    before_action :set_case, only: %i[new create]

    def new
      authorize @case, :can_stop_the_clock?

      @case = CaseStopTheClockDecorator.build(@case)
    end

    def create
      authorize @case, :can_stop_the_clock?

      stop_the_clock_params = params[:case]

      service = CaseStopTheClockService.new(current_user, @case, stop_the_clock_params)
      result = service.call

      case result
      when :ok
        flash[:notice] = I18n.t("cases.stop_the_clocks.create.success")
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseStopTheClockDecorator.build(@case, stop_the_clock_params)

        render :new
      else
        flash[:alert] = I18n.t("cases.stop_the_clocks.create.failure")
        redirect_to case_path(@case.id)
      end
    end
  end
end
