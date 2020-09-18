class CaseTypeFilter
  include FilterParamParsers
  attr_reader :available_choices

  SUB_FILTER_MAP = {
    FOI: ['foi-standard',
          'foi-ir-compliance',
          'foi-ir-timeliness', 
          'overturned-ico'],
    SAR: ['sar-non-offender', 'overturned-ico'],
    OFFENDER_SAR: ['offender-sar'],
    OFFENDER_SAR_COMPLAIN: ['offender-sar-complain']
    ICO: ['ico-appeal']
  }.with_indifferent_access.freeze

  class << self

    def filter_attributes
      [:filter_case_type]
    end

    def template_name
      return 'filter_multiple_choices'
    end
  
    def process_params!(params)
      process_array_param(params, :filter_case_type)
    end
  end

  def initialize(query, user, records)
    @query = query
    @records = records

    @user = user

    @available_choices = {
      :filter_case_type => available_case_types
    }
  end

  def is_available?
    true
  end

  def available_case_types
    user_types = @user.permitted_correspondence_types.map(&:abbreviation)
    types = {}

    user_types.each do | user_type |
      (SUB_FILTER_MAP[user_tpe] || []).each do | sub_filter |
        types.merge!(
          sub_filter => I18n.t("filters.case_types.#{sub_filter}"),
        )
      end
    end
    # merge_foi_types_if_user_eligible!(types, user_types)
    # merge_sar_types_if_user_eligible!(types, user_types)
    # merge_ico_appeal_types_if_user_eligible!(types, user_types)
    # merge_overturned_ico_types_if_user_eligible!(types, user_types)
    # merge_offender_sar_if_user_eligible!(types, user_types)
    types
  end

  # def merge_foi_types_if_user_eligible!(types, user_types)
  #   if "FOI".in?(user_types)
  #     types.merge!(
  #       'foi-standard'      => I18n.t('filters.case_types.foi-standard'),
  #       'foi-ir-compliance' => I18n.t('filters.case_types.foi-ir-compliance'),
  #       'foi-ir-timeliness' => I18n.t('filters.case_types.foi-ir-timeliness'),
  #     )
  #   end
  # end

  # def merge_ico_appeal_types_if_user_eligible!(types, user_types)
  #   if 'ICO'.in?(user_types) && FeatureSet.ico.enabled?
  #     types.merge!(
  #       'ico-appeal' => 'ICO appeals'
  #     )
  #   end
  # end

  # def merge_overturned_ico_types_if_user_eligible!(types, user_types)
  #   if 'FOI'.in?(user_types) || 'SAR'.in?(user_types)
  #     types.merge!(
  #       'overturned-ico' => 'ICO overturned'
  #     )
  #   end
  # end

  # def merge_sar_types_if_user_eligible!(types, user_types)
  #   if "SAR".in?(user_types) && FeatureSet.sars.enabled?
  #     types.merge!(
  #       'sar-non-offender' => I18n.t('filters.case_types.sar-non-offender')
  #     )
  #   end
  # end

  def applied?
    # @query.filter_case_type.present? || @query.filter_sensitivity.present?
    @query.filter_case_type.present?
  end

  def call
    records = @records

    # records = filter_sensitivity(records)
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
      params = {
        'filter_case_type' => [''],
        'parent_id'        => @query.id
      }
      our_crumbs << [crumb_text, params]
    end
    # if @query.filter_sensitivity.present?
    #   sensitivity_text = I18n.t(
    #     "filters.sensitivities.#{@query.filter_sensitivity.first}"
    #   )
    #   crumb_text = I18n.t "filters.crumbs.sensitivity",
    #                       count: @query.filter_sensitivity.size,
    #                       first_value: sensitivity_text,
    #                       remaining_values_count: @query.filter_sensitivity.count - 1
    #   params = {
    #     'filter_sensitivity' => [''],
    #     'parent_id'          => @query.id,
    #   }
    #   our_crumbs << [crumb_text, params]
    # end
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

  # def filter_trigger?
  #   'trigger'.in? @query.filter_sensitivity
  # end

  # def filter_non_trigger?
  #   'non-trigger'.in? @query.filter_sensitivity
  # end

  # def filter_sensitivity(records)
  #   if filter_trigger? && !filter_non_trigger?
  #     records.trigger
  #   elsif !filter_trigger? && filter_non_trigger?
  #     records.non_trigger
  #   else
  #     records
  #   end
  # end

  def filter_case_type(records) # rubocop:disable Metrics/CyclomaticComplexity
    filters = @query.filter_case_type.map do |filter|
      case filter
      when 'foi-standard'      then records.standard_foi
      when 'foi-ir-compliance' then records.internal_review_compliance
      when 'foi-ir-timeliness' then records.internal_review_timeliness
      when 'sar-non-offender'  then records.non_offender_sar
      when 'ico-appeal'        then records.ico_appeal
      when 'overturned-ico'    then records.overturned_ico
      when 'offender-sar'    then records.offender_sar
      else
        raise NameError.new("unknown case type filter '#{filter}")
      end
    end
    execute_filters(filters, records)
  end
end
