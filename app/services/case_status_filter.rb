class CaseStatusFilter
  def self.available_statuses
    {
      'open'   => I18n.t('filters.statuses.open'),
      'closed' => I18n.t('filters.statuses.closed'),
    }
  end

  def initialize(query, records)
    @query = query
    @records = records
  end

  def call
    filter_status(@records)
  end

  def crumbs
    if @query.filter_status.present?
      status_text = I18n.t(
        "filters.statuses.#{@query.filter_status.first}"
      )
      crumb_text = I18n.t "filters.crumbs.status",
                          count: @query.filter_status.size,
                          first_value: status_text,
                          remaining_values_count: @query.filter_status.count - 1
      params = @query.query.merge(
        'filter_status' => [''],
        'parent_id'     => @query.id
      )
      [[crumb_text, params]]
    else
      []
    end
  end

  private

  def filter_open?
    'open'.in? @query.filter_status
  end

  def filter_closed?
    'closed'.in? @query.filter_status
  end

  def filter_status(records)
    if filter_open? && !filter_closed?
      records.opened
    elsif !filter_open? && filter_closed?
      records.closed
    else
      records
    end
  end
end
