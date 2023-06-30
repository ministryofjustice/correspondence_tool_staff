module CaseFilter
  class CaseComplaintTypeFilter < CaseMultiChoicesFilterBase
    def self.identifier
      "filter_complaint_type"
    end

    def self.filter_attributes
      [:filter_complaint_type]
    end

    def available_choices
      priorities = {}
      Case::SAR::OffenderComplaint.complaint_types.map do |key, _|
        priorities[key] = "Complaint - #{complaint_type_text(key)}"
      end
      { filter_complaint_type: priorities }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { |c_type| %w[OFFENDER_SAR_COMPLAINT].include? c_type.abbreviation }
    end

    def call
      records = @records
      filter_complaint_type(records)
    end

  private

    def complaint_type_text(value)
      I18n.t "helpers.label.offender_sar_complaint.complaint_type.#{value}"
    end

    def filter_complaint_type(records)
      if @query.filter_complaint_type.present?
        filters = @query.filter_complaint_type.map do |complaint_type|
          records.where("properties->>'complaint_type' = ? ", complaint_type)
        end
        filters.reduce(Case::Base.none) do |result, filter|
          result.or(filter)
        end
      end
    end
  end
end
