class CaseStatusFilter
  def self.available_statuses
    {
      'open'   => 'Open',
      'closed' => 'Closed',
    }
  end

  def initialize(query, records)
    @query = query
    @records = records
  end

  def call
    filter_status(@records)
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
