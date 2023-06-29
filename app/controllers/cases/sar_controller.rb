module Cases
  class SarController < CasesController
    include NewCase
    include SARCasesParams

    def initialize
      @correspondence_type = CorrespondenceType.sar
      @correspondence_type_key = "sar"

      super
    end

    def new
      permitted_correspondence_types
      new_case_for @correspondence_type
    end

    def case_type
      Case::SAR::Standard
    end

    def create_params
      create_sar_params
    end

    def edit_params
      edit_sar_params
    end

    def process_closure_params
      process_sar_closure_params
    end

    def respond_params
      respond_sar_params
    end

    def process_date_responded_params
      respond_sar_params
    end
  end
end
