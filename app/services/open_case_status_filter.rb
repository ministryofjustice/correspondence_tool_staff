class OpenCaseStatusFilter

  def self.available_open_case_statuses
    {
        'unassigned'                        =>'Needs reassigning',
        'awaiting_responder'                => 'To be accepted',
        'drafting'                          => 'Draft in progress',
        'pending_dacu_clearance'            => 'Pending clearance - Disclosure',
        'pending_press_office_clearance'    => 'Pending clearance - Press office',
        'pending_private_office_clearance'  => 'Pending clearance - Private office',
        'awaiting_dispatch'                 => 'Ready to send',
        'responded'                         => 'Ready to close'
    }
  end

  def self.filter_attributes
    [:filter_open_case_status]
  end

  def initialize(query, records)
    @query = query
    @records = records
  end

  def call
    if @query.filter_open_case_status.any?
      @records = @records.where(current_state: @query.filter_open_case_status)
    end
    @records
  end

end

