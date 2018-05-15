class AssignedBusinessUnitFilter

  def initialize(search_query_record, results)
    @results = results
    @business_unit_ids = search_query_record.filter_assigned_to_ids
  end

  def call
    if @business_unit_ids.present?
      case_ids = Assignment.responding.where(team_id: @business_unit_ids).where.not(state: 'rejected').pluck(:case_id)
      @results.where(id: case_ids)
    else
      @results
    end
  end

  def self.responding_business_units
    BusinessUnit.active.responding.order(:name)
  end
end
