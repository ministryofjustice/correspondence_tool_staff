module CaseFilter
  class CaseTypeFilter < CaseMultiChoicesFilterBase

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

    def self.identifier
      'filter_case_type'
    end

    def self.filter_attributes
      [:filter_case_type]
    end    

    def available_choices
      user_types = @user.permitted_correspondence_types.map(&:abbreviation)
      types = {}

      user_types.each do | user_type |
        (SUB_FILTER_MAP[user_type] || []).each do | sub_filter |
          types.merge!(
            sub_filter => I18n.t("filters.filter_case_type.#{sub_filter}"),
          )
        end
      end
      { :filter_case_type => types }
    end

    def call
      records = @records

      records = filter_case_type(records)

      records
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
