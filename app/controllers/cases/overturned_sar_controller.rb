module Cases
  class OverturnedSarController < CasesController
    include SARCasesParams
    include OverturnedICOParams
    include OverturnedCase

    def new
      permitted_correspondence_types
      new_overturned_ico_for Case::OverturnedICO::SAR
    end

    def create
      create_case_for_type CorrespondenceType.overturned_sar, 'overturned_sar'
    end

    def respond_params
      respond_overturned_params
    end

    def process_date_responded_params
      respond_overturned_params
    end

    def process_closure_params
      process_sar_closure_params
    end
  end
end
