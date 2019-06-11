module Cases
  class SarController < BaseController
    include NewCase
    include SARCasesParams

    def initialize
      @correspondence_type = CorrespondenceType.sar
      @correspondence_type_key = 'sar'

      super
    end

    def new
      new_case_for @correspondence_type
    end

    def case_type
      Case::SAR::Standard
    end

    def create_params
      create_sar_params
    end

    def edit_params
      edit_sar_params
    end
  end
end
