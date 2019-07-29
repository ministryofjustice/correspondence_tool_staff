module Cases
  class FoiController < CasesController
    include NewCase
    include FOICasesParams

    def initialize
      @correspondence_type = CorrespondenceType.foi
      @correspondence_type_key = 'foi'

      super
    end

    def new
      permitted_correspondence_types
      new_case_for @correspondence_type
    end

    def case_type
      foi_type = params.dig(@correspondence_type_key, 'type')
      return Case::FOI::Standard if foi_type.blank?
      Case::FOI::Standard.factory(foi_type)
    end

    def create_params
      create_foi_params
    end

    def edit_params
      edit_foi_params
    end

    def process_closure_params
      process_foi_closure_params
    end

    def respond_params
      respond_foi_params
    end

    def process_date_responded_params
      respond_foi_params
    end
  end
end
