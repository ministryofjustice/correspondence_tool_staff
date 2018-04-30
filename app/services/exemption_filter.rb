class ExemptionFilter

  def initialize(search_query_record, arel)
    puts ">>>>>>>>>> exemption_filter #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    @arel = arel
    @query = search_query_record.query
    @exemption_ids = (@query['exemption_ids'] + @query['common_exemption_ids'])
    @exemption_ids.delete('')
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

  private

  def ids_of_cases_with_all_exemptions
    sql = "select case_id from cases_exemptions where exemption_id in (#{@exemption_ids.join(',')}) group by case_id having count(*) >= #{@exemption_ids.size}"
    CaseExemption.find_by_sql(sql).map(&:case_id)
  end
end
