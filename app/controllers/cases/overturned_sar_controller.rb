module Cases
  class OverturnedSarController < BaseController
    include OverturnedICOParams
    include OverturnedCase
    #include CreateCase

    def new
      new_overturned_ico_for Case::OverturnedICO::SAR
    end

    def create
      create_case_for_type CorrespondenceType.overturned_sar, 'overturned_sar'
    end
  end
end
