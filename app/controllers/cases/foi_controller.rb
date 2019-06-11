module Cases
  class FoiController < BaseController
    include NewCase
    include FOICasesParams

    def initialize
      @correspondence_type = CorrespondenceType.foi
      @correspondence_type_key = 'foi'

      super
    end

    def new
      new_case_for @correspondence_type
    end

    def case_type
      Case::FOI::Standard.factory(params.dig(@correspondence_type_key, 'type'))
    end

    def create_params
      create_foi_params
    end

    def edit_params
      edit_foi_params
    end
  end
end
