module CaseFilter
  class CaseTypeFilter < CaseFilterBase

    SUB_FILTER_MAP = {
      FOI: ['foi-standard',
            'foi-ir-compliance',
            'foi-ir-timeliness', 
            'overturned-ico'],
      SAR: ['sar-non-offender', 'overturned-ico'],
      OFFENDER_SAR: ['offender-sar'],
      OFFENDER_SAR_COMPLAIN: ['offender-sar-complain'],
      ICO: ['ico-appeal']
    }.with_indifferent_access.freeze

    class << self
      def filter_attributes
        [:filter_case_type]
      end    

      def self.set_params(params)
        params.permit(filter_case_type: [])
      end 
    end

    def get_available_choices
      user_types = @user.permitted_correspondence_types.map(&:abbreviation)
      types = {}

      user_types.each do | user_type |
        (SUB_FILTER_MAP[user_type] || []).each do | sub_filter |
          types.merge!(
            sub_filter => I18n.t("filters.case_types.#{sub_filter}"),
          )
        end
      end
      { :filter_case_type => types }
    end

    # def applied?
    #   @query.filter_case_type.present?
    # end

    def call
      records = @records

      records = filter_case_type(records)

      records
    end

    def crumbs
      our_crumbs = []
      if applied?
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
end
