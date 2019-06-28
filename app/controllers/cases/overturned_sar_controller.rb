module Cases
  class OverturnedSarController < CasesController
    include SARCasesParams
    include OverturnedICOParams
    include OverturnedCase

    def initialize
      @correspondence_type = CorrespondenceType.overturned_sar
      @correspondence_type_key = 'overturned_sar'

      super
    end

    # The 'new' action for this type needs an original case -
    # so it doesn't fit the normal rails pattern.
    def new
      authorize case_type, :can_add_case?
      permitted_correspondence_types
      new_overturned_ico_for case_type
    end

    def case_type
      Case::OverturnedICO::SAR
    end

    def create_params
      pams = create_ico_overturned_sar_params
      puts "\n\nHIT CREATE PARAMS OverturnedSarController:\n#{pams.inspect}\n"
      pams
    end

    def respond_params
      respond_overturned_params
    end

    def process_date_responded_params
      respond_overturned_params
    end

    def process_closure_params
      process_sar_closure_params
    end
  end
end
