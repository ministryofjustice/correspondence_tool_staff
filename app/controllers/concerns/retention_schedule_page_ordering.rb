module RetentionSchedulePageOrdering
  extend ActiveSupport::Concern

  def set_retention_schedule_order_flag
    set_initial_retention_shedule_order_flag
    if order_flag_is_not_applicable_to_retention_schedules
      set_order_cookie(
        SearchHelper::RETENTION_SCHEDULE_DEFAULT_SEARCH_RESULT_ORDER_FLAG
      )
    else
      set_cookie_order_flag
    end
  end

  def set_initial_retention_shedule_order_flag
    if cookies[:search_result_order].nil? || order_flag_is_not_applicable_to_retention_schedules
      set_order_cookie(
        SearchHelper::RETENTION_SCHEDULE_DEFAULT_SEARCH_RESULT_ORDER_FLAG
      )
    end
  end

  def reset_default_order_from_retention_schedule_order_flag
    if order_flag_is_not_applicable_to_retention_schedules
      set_cookie_order_flag
    else
      set_order_cookie(
        SearchHelper::DEFAULT_SEARCH_RESULT_ORDER_FLAG
      )
    end
  end

  def order_flag_is_not_applicable_to_retention_schedules
    # 'destruction_date' is the common part of the SEARCH_SCOPE_SET
    # for the RetentionSchedule page. See the SearchHelper module.
    if cookies[:search_result_order]
      cookies[:search_result_order].exclude?('destruction_date')
    end
  end
end
