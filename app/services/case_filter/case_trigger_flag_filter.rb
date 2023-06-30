module CaseFilter
  class CaseTriggerFlagFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_sensitivity"
    end

    def self.filter_attributes
      [:filter_sensitivity]
    end

    def available_choices
      {
        filter_sensitivity: {
          "non-trigger" => I18n.t("filters.filter_sensitivity.non-trigger"),
          "trigger" => I18n.t("filters.filter_sensitivity.trigger"),
        },
      }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { |c_type| %w[FOI].include? c_type.abbreviation }
    end

    def call
      records = @records
      filter_sensitivity(records)
    end

  private

    def filter_trigger?
      "trigger".in? @query.filter_sensitivity
    end

    def filter_non_trigger?
      "non-trigger".in? @query.filter_sensitivity
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
end
