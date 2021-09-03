module SearchHelper

  SEARCH_SCOPE_SET = [
    {"name" => :search_result_order_by_oldest_first, "order" => "cases.received_date ASC"},
    {"name" => :search_result_order_by_newest_first, "order" => "cases.received_date DESC"},
  ]

  DEFAULT_SEARCH_RESULT_ORDER_FLAG = "search_result_order_by_oldest_first"

end