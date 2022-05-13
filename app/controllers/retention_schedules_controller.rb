class RetentionSchedulesController < ApplicationController

  def bulk_update
    service = RetentionSchedulesUpdateService.new(
      retention_schedules_params: retention_schedules_params,
      event_text: params[:commit],
      current_user: current_user
    )

    service.call

    if service.result == :error
      flash[:alert] = service.error_message
      redirect_to '/cases/retention'
    else
      success_message = "#{service.case_count} cases have been #{service.post_update_message}"
      flash[:notice] = success_message
      redirect_to '/cases/retention'
    end
  end


  private

  def retention_schedules_params
    params.require(:retention_schedules).require(:case_ids).permit!
  end
end
