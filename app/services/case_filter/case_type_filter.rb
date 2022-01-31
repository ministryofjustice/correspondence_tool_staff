module CaseFilter
  class CaseTypeFilter < CaseMultiChoicesFilterBase

    SUB_FILTER_MAP = {
      'foi-standard': ['FOI'],
      'foi-ir-compliance': ['FOI'],
      'foi-ir-timeliness': ['FOI'],
      'sar-non-offender': ['SAR'], 
      'sar-ir-compliance': ['SAR_INTERNAL_REVIEW'],
      'sar-ir-timeliness': ['SAR_INTERNAL_REVIEW'],
      'ico-appeal': ['ICO'],
      'overturned-ico': ['FOI', 'SAR'],
      'offender-sar': ['OFFENDER_SAR'],
      'offender-sar-complaint': ['OFFENDER_SAR_COMPLAINT'],
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

      SUB_FILTER_MAP.to_hash.each do | sub_filter, allowed_case_types |
        if (user_types & allowed_case_types).present?
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
        when 'foi-standard'           then records.standard_foi
        when 'foi-ir-compliance'      then records.internal_review_compliance
        when 'foi-ir-timeliness'      then records.internal_review_timeliness
        when 'sar-non-offender'       then records.non_offender_sar
        when 'sar-ir-compliance'      then records.sar_ir_compliance
        when 'sar-ir-timeliness'      then records.sar_ir_timeliness 
        when 'ico-appeal'             then records.ico_appeal
        when 'overturned-ico'         then records.overturned_ico
        when 'offender-sar'           then records.offender_sar
        when 'offender-sar-complaint' then records.offender_sar_complaint
        else
          raise NameError.new("unknown case type filter '#{filter}")
        end
      end
      execute_filters(filters, records)
    end
  end
end
