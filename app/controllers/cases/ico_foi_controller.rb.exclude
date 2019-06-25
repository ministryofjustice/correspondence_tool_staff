module Cases
  class IcoFoiController < CasesController
    include ICOCasesParams
    include NewCase

    def new
      @correspondence_type_key = 'ico'
      permitted_correspondence_types
      new_case_for CorrespondenceType.ico
    end

    def create
      create_case_for_type CorrespondenceType.ico, 'ico'
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
