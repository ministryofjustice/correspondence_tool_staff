module Cases
  class IcoFoiController < CasesController
    include ICOCasesParams
    include NewCase

    def initialize
      @correspondence_type = CorrespondenceType.ico
      @correspondence_type_key = 'ico'

      super
    end

    def new
      permitted_correspondence_types
      new_case_for @correspondence_type
    end

    def case_type
      Case::OverturnedICO::FOI
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
