module Cases
  class OverturnedFoiController < CasesController
    include FOICasesParams
    include OverturnedICOParams
    include OverturnedCase

    def initialize
      @correspondence_type = CorrespondenceType.overturned_foi
      @correspondence_type_key = 'overturned_foi'

      super
    end

    # The 'new' action for this type needs an original case -
    # so it doesn't fit the normal rails pattern.
    def new
      permitted_correspondence_types
      new_overturned_ico_for Case::OverturnedICO::FOI
    end

    def respond_params
      respond_overturned_params
    end

    def process_date_responded_params
      respond_overturned_params
    end

    def process_closure_params
      process_foi_closure_params
    end
  end
end
