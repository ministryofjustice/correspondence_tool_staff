class CaseTriggerFlagFilter
  include FilterParamParsers
  attr_reader :available_choices

  class << self
    def available_sensitivities
      {
        'non-trigger' => I18n.t('filters.sensitivities.non-trigger'),
        'trigger'     => I18n.t('filters.sensitivities.trigger'),
      }
    end

    def filter_attributes
      [:filter_sensitivity]
    end

    def process_params!(params)
      process_array_param(params, :filter_sensitivity)
    end

    def template_name
      return 'filter_multiple_choices'
    end
  end

  def initialize(query, user, records)
    @query = query
    @records = records

    @user = user
    @available_choices = self.class.available_sensitivities
  end

  def is_available?
    @user.permitted_correspondence_types.any? { | c_type | c_type.foi? || c_type.sar? || c_type.ico? }
  end

  def applied?
    @query.filter_case_type.present? || @query.filter_sensitivity.present?
  end

  def call
    records = @records
    records = filter_sensitivity(records)
    records
  end

  def crumbs
    our_crumbs = []
    if @query.filter_sensitivity.present?
      sensitivity_text = I18n.t(
        "filters.sensitivities.#{@query.filter_sensitivity.first}"
      )
      crumb_text = I18n.t "filters.crumbs.sensitivity",
                          count: @query.filter_sensitivity.size,
                          first_value: sensitivity_text,
                          remaining_values_count: @query.filter_sensitivity.count - 1
      params = {
        'filter_sensitivity' => [''],
        'parent_id'          => @query.id,
      }
      our_crumbs << [crumb_text, params]
    end
    our_crumbs
  end

  private

  def execute_filters(filters, records)
    if filters.present?
      filters.reduce(Case::Base.none) do |result, filter|
        result.or(filter)
      end
    else
      records
    end
  end

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
end
