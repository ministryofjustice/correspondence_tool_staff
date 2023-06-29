module CaseFilter
  class TimelinessFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_timeliness"
    end

    def self.filter_attributes
      [:filter_timeliness]
    end

    def available_choices
      {
        filter_timeliness: {
          "in_time" => I18n.t("filters.filter_timeliness.in_time"),
          "late" => I18n.t("filters.filter_timeliness.late"),
        },
      }
    end

    def call
      filter_timeliness(@records)
    end

  private

    def filter_in_time?
      "in_time".in? @query.filter_timeliness
    end

    def filter_late?
      "late".in? @query.filter_timeliness
    end

    def filter_timeliness(records)
      if filter_in_time? && !filter_late?
        records.in_time
      elsif !filter_in_time? && filter_late?
        records.late
      else
        records
      end
    end
  end
end
