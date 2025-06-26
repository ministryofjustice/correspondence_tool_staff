module CaseFilter
  class CaseDpsMissingDataFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_dps_missing_data"
    end

    def self.filter_attributes
      [:filter_dps_missing_data]
    end

    def available_choices
      {
        filter_dps_missing_data: {
          "dps-missing-data" => I18n.t("filters.filter_dps_missing_data.dps-missing-data"),
          "not-dps-missing-data" => I18n.t("filters.filter_dps_missing_data.not-dps-missing-data"),
        },
      }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { |c_type| %w[OFFENDER_SAR].include? c_type.abbreviation }
    end

    def call
      records = @records
      filter_dps_missing_data(records)
    end

  private

    def is_dps_missing_data?
      "dps-missing-data".in? @query.filter_dps_missing_data
    end

    def is_not_dps_missing_data?
      "not-dps-missing-data".in? @query.filter_dps_missing_data
    end

    def filter_dps_missing_data(records)
      if is_dps_missing_data? && !is_not_dps_missing_data?
        records.dps_missing_data
      elsif !is_dps_missing_data? && is_not_dps_missing_data?
        records.not_dps_missing_data
      else
        records
      end
    end
  end
end
