module CaseFilter
  class CaseTypeFilter < CaseMultiChoicesFilterBase
    SUB_FILTER_MAP = {
      'foi-standard': %w[FOI],
      'foi-ir-compliance': %w[FOI],
      'foi-ir-timeliness': %w[FOI],
      'sar-non-offender': %w[SAR],
      'sar-ir-compliance': %w[SAR_INTERNAL_REVIEW],
      'sar-ir-timeliness': %w[SAR_INTERNAL_REVIEW],
      'ico-appeal': %w[ICO],
      'overturned-ico': %w[FOI SAR],
      'offender-sar': %w[OFFENDER_SAR],
      'offender-sar-complaint': %w[OFFENDER_SAR_COMPLAINT],
    }.with_indifferent_access.freeze

    def self.identifier
      "filter_case_type"
    end

    def self.filter_attributes
      [:filter_case_type]
    end

    def available_choices
      user_types = @user.permitted_correspondence_types.map(&:abbreviation)
      types = {}

      SUB_FILTER_MAP.to_hash.each do |sub_filter, allowed_case_types|
        next if (user_types & allowed_case_types).blank?

        types.merge!(
          sub_filter => I18n.t("filters.filter_case_type.#{sub_filter}"),
        )
      end

      { filter_case_type: types }
    end

    def call
      records = @records

      filter_case_type(records)
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

    def filter_case_type(records)
      filters = @query.filter_case_type.map do |filter|
        case filter
        when "foi-standard"           then records.standard_foi
        when "foi-ir-compliance"      then records.internal_review_compliance
        when "foi-ir-timeliness"      then records.internal_review_timeliness
        when "sar-non-offender"       then records.non_offender_sar
        when "sar-ir-compliance"      then records.sar_ir_compliance
        when "sar-ir-timeliness"      then records.sar_ir_timeliness
        when "ico-appeal"             then records.ico_appeal
        when "overturned-ico"         then records.overturned_ico
        when "offender-sar"           then records.offender_sar
        when "offender-sar-complaint" then records.offender_sar_complaint
        else
          raise NameError, "unknown case type filter '#{filter}"
        end
      end
      execute_filters(filters, records)
    end
  end
end
