module Cases
  class OffenderSarComplaintController < OffenderSarController

    include OffenderSARComplaintCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = 'offender_sar_complaint'
    end

    def start_complaint
      params.merge!(:current_step => "link-offender-sar-case")
      params.merge!(:commit => true)
      params[@correspondence_type_key] = {}
      params[@correspondence_type_key].merge!("original_case_number" => params["number"])
      create
    end

    def set_case_types
      @case_types = ["Case::SAR::OffenderComplaint"]
    end

    def case_type
      Case::SAR::OffenderComplaint
    end

    def create_params
      create_offender_sar_complaint_params
    end

    def edit_params
      create_offender_sar_complaint_params
    end

    def update_params
      create_offender_sar_complaint_params
    end

    def process_closure_params
      process_offender_sar_complaint_closure_params
    end

    def process_date_responded_params
      respond_offender_sar_complaint_params
    end

  end
end
