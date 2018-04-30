class CaseTypeFilter
  def self.available_sensitivities
    {
      'non-trigger' => 'Non-trigger',
      'trigger'     => 'Trigger',
    }
  end

  def self.available_case_types
    {
      'foi-standard' => 'FOI - Standard',
      'foi-ir-compliance' => 'FOI - Internal review for compliance',
      'foi-ir-timeliness' => 'FOI - Internal review for timeliness',
    }
  end

  def initialize(query, records)
    @query = query
    @records = records
  end

  def call
    records = @records

    records = filter_sensitivity(records)
    records = filter_case_type(records)

    records
  end

  private

  def filter_trigger?
    'trigger'.in? @query.filter_sensitivity
  end

  def filter_non_trigger?
    'non-trigger'.in? @query.filter_sensitivity
  end

  def filter_sensitivity(records)
    if filter_trigger? && !filter_non_trigger?
      records.trigger
    elsif !filter_trigger? && filter_non_trigger?
      records.non_trigger
    else
      records
    end
  end

  def filter_case_type(records)
    filters = @query.filter_case_type.map do |filter|
      case filter
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
      records
    end
  end
end
