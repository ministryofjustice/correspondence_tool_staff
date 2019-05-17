module Cases
  class OverturnedFoiController < BaseController
    include OverturnedICOParams
    include OverturnedCase
    include CreateCase

    # The 'new' action for this type needs an original case -
    # so it doesn't fit the normal rails pattern.
    def new
      new_overturned_ico_for Case::OverturnedICO::FOI
    end

    def create
      create_case_for_type CorrespondenceType.overturned_foi, 'overturned_foi'
    end
  end
end
