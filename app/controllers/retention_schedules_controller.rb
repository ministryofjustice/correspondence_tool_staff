class RetentionSchedulesController < ApplicationController
  include FormObjectUpdatable

  before_action :set_case,
                :authorize_action, only: [:edit, :update]

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

  def edit
    @form_object = RetentionScheduleForm.build(
      current_retention_schedule
    )
  end

  def update
    update_and_advance(RetentionScheduleForm, record: current_retention_schedule) do |form_object|
      annotate_case!(
        form_object.record.saved_changes
      )
      redirect_to case_path(@case), flash: { notice: t('.flash.success') }
    end
  end

  private

  def authorize_action
    authorize @case, :can_perform_retention_actions?
  end

  def annotate_case!(changes)
    RetentionScheduleCaseNote.log!(
      kase: @case, user: @user, changes: changes
    )
  end

  def set_case
    @case = current_retention_schedule.case
  end

  def current_retention_schedule
    @_current_retention_schedule ||= RetentionSchedule.find(
      params.require(:id)
    )
  end

  def retention_schedules_params
    params.require(:retention_schedules).require(:case_ids).permit!
  end
end
