module SearchParams
  extend ActiveSupport::Concern

  def search_params
    params.fetch(:search_query, {}).permit(
      :search_text,
      :parent_id,
      :external_deadline_from,
      :external_deadline_from_dd,
      :external_deadline_from_mm,
      :external_deadline_from_yyyy,
      :external_deadline_to,
      :external_deadline_to_dd,
      :external_deadline_to_mm,
      :external_deadline_to_yyyy,
      :received_date_from,
      :received_date_from_dd,
      :received_date_from_mm,
      :received_date_from_yyyy,
      :received_date_to,
      :received_date_to_dd,
      :received_date_to_mm,
      :received_date_to_yyyy,
      common_exemption_ids: [],
      exemption_ids: [],
      filter_assigned_to_ids: [],
      filter_case_type: [],
      filter_open_case_status: [],
      filter_sensitivity: [],
      filter_status: [],
      filter_timeliness: []
    )
  end
end
