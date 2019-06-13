module Cases
  class IcoSarController < CasesController
    include ICOCasesParams
    include CreateCase
    include NewCase

    def new
      @correspondence_type_key = 'sar'
      new_case_for CorrespondenceType.sar
    end

    def create
      create_case_for_type CorrespondenceType.sar, 'sar'
    end
  end
end
