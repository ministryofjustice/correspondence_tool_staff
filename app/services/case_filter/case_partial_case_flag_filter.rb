module CaseFilter
  class CasePartialCaseFlagFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_partial_case_flag"
    end

    def self.filter_attributes
      [:filter_partial_case_flag]
    end

    def available_choices
      {
        filter_partial_case_flag: {
          "partial-case" => I18n.t("filters.filter_partial_case_flag.partial-case"),
          "not-partial-case" => I18n.t("filters.filter_partial_case_flag.not-partial-case"),
        },
      }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { |c_type| %w[OFFENDER_SAR].include? c_type.abbreviation }
    end

    def call
      records = @records
      filter_partial_case(records)
    end

  private

    def is_partial_case?
      "partial-case".in? @query.filter_partial_case_flag
    end

    def is_not_partial_case?
      "not-partial-case".in? @query.filter_partial_case_flag
    end

    def filter_partial_case(records)
      if is_partial_case? && !is_not_partial_case?
        records.partial_case
      elsif !is_partial_case? && is_not_partial_case?
        records.not_partial_case
      else
        records
      end
    end
  end
end
