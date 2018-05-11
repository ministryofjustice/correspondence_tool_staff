class AssignedBusinessUnitFilter
  def self.filter_attributes
    [:filter_assigned_to_ids]
  end

  def initialize(search_query_record, results)
    @results = results
    @query = search_query_record
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

  def crumbs
    if @business_unit_ids.present?
      first_business_unit = BusinessUnit.find(@business_unit_ids.first)
      crumb_text = I18n.t "filters.crumbs.assigned_business_units",
                          count: @business_unit_ids.count,
                          first_value: first_business_unit.name,
                          remaining_values_count: @business_unit_ids.count - 1
      params = @query.query.merge(
        'filter_assigned_to_ids' => [''],
        'parent_id'              => @query.id,
      )
      [[crumb_text, params]]
    else
      []
    end
  end
end
