class ExemptionFilter
  def self.filter_attributes
    [:common_exemption_ids, :exemption_ids]
  end

  def initialize(search_query_record, arel)
    @arel = arel
    @query = search_query_record
    @exemption_ids = search_query_record.exemption_ids
  end

  def call
    if @exemption_ids.any?
      kase_ids = ids_of_cases_with_all_exemptions
      @arel.where(id: kase_ids)
    else
      @arel
    end
  end

  def self.available_common_exemptions
    CaseClosure::Exemption.most_frequently_used
  end

  def self.available_exemptions
    CaseClosure::Metadatum.exemption_ncnd_refusal
  end

  def crumbs
    if @exemption_ids.present?
      first_exemption = CaseClosure::Exemption.find(@exemption_ids.first)
      crumb_text = I18n.t "filters.crumbs.exemptions",
                          count: @exemption_ids.count,
                          first_value: first_exemption.name,
                          remaining_values_count: @exemption_ids.count - 1
      params = @query.query.merge(
        'exemption_ids' => [''],
        'parent_id'     => @query.id,
      )
      [[crumb_text, params]]
    else
      []
    end
  end

  private

  def ids_of_cases_with_all_exemptions
    sql = "select case_id from cases_exemptions where exemption_id in (#{@exemption_ids.join(',')}) group by case_id having count(*) >= #{@exemption_ids.size}"
    CaseExemption.find_by_sql(sql).map(&:case_id)
  end
end
