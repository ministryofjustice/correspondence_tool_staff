module CaseFilter
  class CaseComplaintPriorityFilter < CaseMultiChoicesFilterBase

    def self.identifier
      'filter_complaint_priority'
    end
  
    def self.filter_attributes
      [:filter_complaint_priority]
    end

    def available_choices
      priorities = {}
      Case::SAR::OffenderComplaint.priorities.map do |key, value| 
        priorities[key] = value.humanize
      end
      { filter_complaint_priority: priorities}
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { | c_type | ['OFFENDER_SAR_COMPLAINT'].include? c_type.abbreviation }
    end

    def call
      records = @records
      records = filter_complaint_priority(records)
      records
    end

    private

    def filter_complaint_priority(records)
      if @query.filter_complaint_priority.present?
        filters = @query.filter_complaint_priority.map do |priority|
          records.where("properties->>'priority' = ? ", priority)
        end
        filters.reduce(Case::Base.none) do |result, filter|
          result.or(filter)
        end
      end
    end
  end
end
