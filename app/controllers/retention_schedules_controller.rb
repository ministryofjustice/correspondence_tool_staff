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
      add_note_to_case!(
        form_object.previous_values
      )
      redirect_to case_path(@case), flash: { notice: t('.flash.success') }
    end
  end

  private

  def authorize_action
    authorize @case, :can_perform_retention_actions?
  end

  def add_note_to_case!(previous_values)
    @case.state_machine.add_note_to_case!(
      acting_user: @user,
      acting_team: @user.case_team(@case),
      message: t('retention_schedules.update.case_note_html',
                 state_from: previous_values[:state],
                 state_to: current_retention_schedule.human_state,
                 date_from: l(previous_values[:date], format: :compact),
                 date_to: l(current_retention_schedule.planned_destruction_date, format: :compact))
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
