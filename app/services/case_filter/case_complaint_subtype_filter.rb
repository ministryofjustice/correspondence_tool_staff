module CaseFilter
  class CaseComplaintSubtypeFilter < CaseMultiChoicesFilterBase

    def self.identifier
      'filter_complaint_subtype'
    end
  
    def self.filter_attributes
      [:filter_complaint_subtype]
    end

    def available_choices
      subtypes = {}
      Case::SAR::OffenderComplaint.complaint_subtypes.map do |key, value| 
        subtypes[key] = I18n.t("helpers.label.offender_sar_complaint.complaint_subtype.#{value}", default: value.humanize)
      end
      { filter_complaint_subtype: subtypes}
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { | c_type | ['OFFENDER_SAR_COMPLAINT'].include? c_type.abbreviation }
    end

    def call
      records = @records
      records = filter_complaint_subtype(records)
      records
    end

    private

    def filter_complaint_subtype(records)
      if @query.filter_complaint_subtype.present?
        filters = @query.filter_complaint_subtype.map do |subtype|
          records.where("properties->>'complaint_subtype' = ? ", subtype)
        end
        filters.reduce(Case::Base.none) do |result, filter|
          result.or(filter)
        end
      end
    end
  end
end
