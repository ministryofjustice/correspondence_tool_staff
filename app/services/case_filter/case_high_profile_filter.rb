module CaseFilter
  class CaseHighProfileFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_high_profile"
    end

    def self.filter_attributes
      [:filter_high_profile]
    end

    def available_choices
      {
        filter_high_profile: {
          "high-profile" => I18n.t("filters.filter_high_profile.high-profile"),
          "not-high-profile" => I18n.t("filters.filter_high_profile.not-high-profile"),
        },
      }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { |c_type| %w[OFFENDER_SAR OFFENDER_SAR_COMPLAINT].include? c_type.abbreviation }
    end

    def call
      records = @records
      filter_high_profile(records)
    end

  private

    def is_high_profile?
      "high-profile".in? @query.filter_high_profile
    end

    def is_not_high_profile?
      "not-high-profile".in? @query.filter_high_profile
    end

    def filter_high_profile(records)
      if is_high_profile? && !is_not_high_profile?
        records.high_profile
      elsif !is_high_profile? && is_not_high_profile?
        records.not_high_profile
      else
        records
      end
    end
  end
end
