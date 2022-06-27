module SearchHelper

  SEARCH_SCOPE_SET = {
    search_result_order_by_oldest_first: { "order" => "cases.id ASC"},
    search_result_order_by_newest_first: {"order" => "cases.received_date DESC, cases.id DESC"},
    search_result_order_by_oldest_destruction_date: {"order" => 'retention_schedule.planned_destruction_date ASC'},
    search_result_order_by_newest_destruction_date: {"order" => 'retention_schedule.planned_destruction_date DESC'},
    search: {"order" => nil},
  }.freeze

  DEFAULT_SEARCH_RESULT_ORDER_FLAG = "search_result_order_by_oldest_first".freeze

  RETENTION_SCHEDULE_DEFAULT_SEARCH_RESULT_ORDER_FLAG = "search_result_order_by_oldest_destruction_date".freeze

  def self.get_order_option(search_order_choice)
    if SEARCH_SCOPE_SET[search_order_choice.to_sym].present?
      chosen_scope = search_order_choice
    else
      chosen_scope = DEFAULT_SEARCH_RESULT_ORDER_FLAG
    end
    chosen_scope
  end

  def self.get_order_fields(search_order_choice)
    chosen_scope = SEARCH_SCOPE_SET[search_order_choice.to_sym] || SEARCH_SCOPE_SET[DEFAULT_SEARCH_RESULT_ORDER_FLAG]
    chosen_scope["order"]
  end

end
