class RetentionSchedulesController < ApplicationController
  def bulk_update
    status_action = parameterize_status_action

    case_ids = prepare_case_ids

    case status_action
    when :further_review_needed
      update_retention_schedule_statuses(
        case_ids: case_ids, 
        new_status: 'review'
      ) 
    when :retain
      update_retention_schedule_statuses(
        case_ids: case_ids, 
        new_status: 'retain'
      ) 
    when :mark_for_destruction
      update_retention_schedule_statuses(
        case_ids: case_ids, 
        new_status: 'erasable'
      ) 
    end

    redirect_to '/cases/retention'
  end


  private

  def retention_schedules_params
    params.require(:retention_schedules).require(:case_ids).permit!
  end

  def prepare_case_ids
    # check_boxes submit as { <case_id> => 1 } if selected
    # or { <case_id> => 0 } if not 
    retention_schedules_params.to_h.filter_map do |key, value|
      key if value == "1"
    end
  end

  def parameterize_status_action
    params[:commit].parameterize(separator: "_").to_sym
  end

  def update_retention_schedule_statuses(case_ids:, new_status:)
    case_ids.each do |case_id|
      kase = Case::Base.includes(:retention_schedule).find(case_id)

      if kase
        retention_schedule = kase.retention_schedule
        retention_schedule.status = new_status
        if retention_schedule.valid? 
          retention_schedule.save
        end
      end
    end
  end
end
