class OpenCaseStatusFilter

  def self.available_open_case_statuses
    {
      'unassigned'                       => I18n.t('filters.open_case_statuses.unassigned'),
      'awaiting_responder'               => I18n.t('filters.open_case_statuses.awaiting_responder'),
      'drafting'                         => I18n.t('filters.open_case_statuses.drafting'),
      'pending_dacu_clearance'           => I18n.t('filters.open_case_statuses.pending_dacu_clearance'),
      'pending_press_office_clearance'   => I18n.t('filters.open_case_statuses.pending_press_office_clearance'),
      'pending_private_office_clearance' => I18n.t('filters.open_case_statuses.pending_private_office_clearance'),
      'awaiting_dispatch'                => I18n.t('filters.open_case_statuses.awaiting_dispatch'),
      'responded'                        => I18n.t('filters.open_case_statuses.responded'),
    }
  end

  def self.filter_attributes
    [:filter_open_case_status]
  end

  def initialize(query, records)
    @query = query
    @records = records
  end

  def applied?
    @query.filter_open_case_status.present?
  end

  def call
    if @query.filter_open_case_status.any?
      @records = @records.where(current_state: @query.filter_open_case_status)
    end
    @records
  end

  def crumbs
    if applied?
      status_text = I18n.t(
        "filters.open_case_statuses.#{@query.filter_open_case_status.first}"
      )
      crumb_text = I18n.t "filters.crumbs.open_case_status",
                          count: @query.filter_open_case_status.size,
                          first_value: status_text,
                          remaining_values_count: @query.filter_open_case_status.count - 1
      params = @query.query.merge(
        'filter_open_case_status' => [''],
        'parent_id'               => @query.id
      )
      [[crumb_text, params]]
    else
      []
    end
  end
end

