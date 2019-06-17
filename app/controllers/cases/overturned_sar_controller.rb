module Cases
  class OverturnedSarController < CasesController
    include OverturnedICOParams
    include OverturnedCase

    def new
      new_overturned_ico_for Case::OverturnedICO::SAR
    end

    def create
      create_case_for_type CorrespondenceType.overturned_sar, 'overturned_sar'
    end
  end
end
