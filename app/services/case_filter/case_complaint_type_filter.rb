module CaseFilter
  class CaseComplaintTypeFilter < CaseMultiChoicesFilterBase

    def self.identifier
      'filter_complaint_type'
    end
  
    def self.filter_attributes
      [:filter_complaint_type]
    end

    def available_choices
      priorities = {}
      Case::SAR::OffenderComplaint.complaint_types.map  do |key, value| 
        priorities[key] = "Complaint - #{value}"
      end
      { :filter_complaint_type => priorities}
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { | c_type | ['OFFENDER_SAR_COMPLAINT'].include? c_type.abbreviation }
    end

    def call
      records = @records
      records = filter_complaint_type(records)
      records
    end

    private

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
