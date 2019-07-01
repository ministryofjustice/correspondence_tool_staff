module Cases
  class IcoSarController < CasesController
    include ICOCasesParams
    include NewCase

    def initialize
      @correspondence_type = CorrespondenceType.sar
      @correspondence_type_key = 'sar'

      super
    end

    # The 'new' action for this type needs an original case -
    # so it doesn't fit the normal rails pattern.
    def new
      authorize case_type, :can_add_case?
      permitted_correspondence_types
      new_overturned_ico_for case_type
    end

    def case_type
      Case::ICO::SAR
    end

    def create_params
      create_ico_params
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
