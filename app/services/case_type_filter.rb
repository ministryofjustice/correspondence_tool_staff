module CaseTypeFilter
  def self.call(query, records)
    @@query = query

    # unless query[:filter_sensitivity].blank?
      records = filter_sensitivity(query, records)
    # end

    # unless query[:filter_case_type].blank?
      records = filter_case_type(query, records)
    # end

    records
  end

  def self.filter_trigger?
    'trigger'.in? @@query['filter_sensitivity']
  end

  def self.filter_non_trigger?
    'non-trigger'.in? @@query['filter_sensitivity']
  end

  def self.filter_sensitivity(query, records)
    if filter_trigger? && !filter_non_trigger?
      records.trigger
    elsif !filter_trigger? && filter_non_trigger?
      records.non_trigger
    end
  end

  def self.filter_case_type(query, records)
    filters = query['filter_case_type'].map do |filter|
      case filter
      when ''                  then records
      when 'foi-standard'      then records.standard_foi
      when 'foi-ir-compliance' then records.internal_review_compliance
      when 'foi-ir-timeliness' then records.internal_review_timeliness
      else
        raise NameError.new("unknown case type filter '#{filter}")
      end
    end

    if filters.present?
      filters.reduce(Case::Base.none) do |result, filter|
        result.or(filter)
      end
    else
      Case::Base.all
    end
  end
end
