module Cases
  class OffenderSarComplaintController < OffenderSarController
    include OffenderSARComplaintCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = 'offender_sar_complaint'
      @case_route_url = 'step_case_sar_offender_complaint_index_path'
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

    def respond_offender_sar_params
      create_offender_sar_complaint_params
    end

  end
end
