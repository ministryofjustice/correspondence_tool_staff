class RetentionSchedulesController < ApplicationController
  def bulk_update
    service = RetentionSchedulesUpdateService.new(
      retention_schedules_params: retention_schedules_params,
      action_text: params[:commit]
    )

    service.call

    if service.result == :error
      flash[:alert] = service.error_message
    else
      success_message = "#{service.case_count} cases retention statuses updated to #{service.status_action}"
      flash[:notice] = success_message
      redirect_to '/cases/retention'
    end
  end


  private

  def retention_schedules_params
    params.require(:retention_schedules).require(:case_ids).permit!
  end
end
