module Cases
  class IcoSarController < CasesController
    include ICOCasesParams
    include NewCase

    def new
      @correspondence_type_key = 'sar'
      permitted_correspondence_types
      new_case_for CorrespondenceType.sar
    end

    def create
      create_case_for_type CorrespondenceType.sar, 'sar'
    end

    def process_closure_params
      process_ico_closure_params
    end

    def respond_params
      respond_ico_params
    end

    def process_date_responded_params
      ico_close_date_responded_params
    end
  end
end
