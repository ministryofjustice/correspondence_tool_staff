module Cases
  class OffenderSarController < BaseController
    include CreateCase
    include NewCase

    def new
      new_case_for CorrespondenceType.offender_sar
    end

    def create
      create_case_for_type CorrespondenceType.offender_sar, 'offender_sar'
    end
  end
end
