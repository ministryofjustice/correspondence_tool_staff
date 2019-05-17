module Cases
  class IcoController < BaseController
    include CreateCase
    include NewCase

    def new
      @correspondence_type_key = 'ico'
      new_case_for CorrespondenceType.ico
    end

    def create
      create_case_for_type CorrespondenceType.ico, 'ico'
    end
  end
end
