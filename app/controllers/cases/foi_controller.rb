module Cases
  class FoiController < BaseController
    include CreateCase
    include NewCase

    def new
      @correspondence_type_key = 'foi'
      new_case_for CorrespondenceType.foi
    end

    def create
      create_case_for_type CorrespondenceType.foi, 'foi'
    end
  end
end
