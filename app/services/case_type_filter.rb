class CaseTypeFilter
  def self.available_sensitivities
    {
      'non-trigger' => I18n.t('filters.sensitivities.non-trigger'),
      'trigger'     => I18n.t('filters.sensitivities.trigger'),
    }
  end

  def self.available_case_types
    {
      'foi-standard'      => I18n.t('filters.case_types.foi-standard'),
      'foi-ir-compliance' => I18n.t('filters.case_types.foi-ir-compliance'),
      'foi-ir-timeliness' => I18n.t('filters.case_types.foi-ir-timeliness'),
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

  def crumbs
    our_crumbs = []
    if @query.filter_case_type.present?
      case_type_text = I18n.t(
        "filters.case_types.#{@query.filter_case_type.first}"
      )
      crumb_text = I18n.t "filters.crumbs.case_type",
                          count: @query.filter_case_type.size,
                          first_value: case_type_text,
                          remaining_values_count: @query.filter_case_type.count - 1
      params = @query.query.merge(
        'filter_case_type' => [''],
        'parent_id'        => @query.id
      )
      our_crumbs << [crumb_text, params]
    end
    if @query.filter_sensitivity.present?
      sensitivity_text = I18n.t(
        "filters.sensitivities.#{@query.filter_sensitivity.first}"
      )
      crumb_text = I18n.t "filters.crumbs.sensitivity",
                          count: @query.filter_sensitivity.size,
                          first_value: sensitivity_text,
                          remaining_values_count: @query.filter_sensitivity.count - 1
      params = @query.query.merge(
        'filter_sensitivity' => [''],
        'parent_id'          => @query.id,
      )
      our_crumbs << [crumb_text, params]
    end
    our_crumbs
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
