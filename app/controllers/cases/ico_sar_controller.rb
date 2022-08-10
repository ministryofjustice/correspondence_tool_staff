module Cases
  class IcoSarController < IcoController
    # def new
    #   authorize case_type, :can_add_case?

    #   permitted_correspondence_types
    #   new_case_for @correspondence_type, case_type
    # end
    def case_type
      Case::ICO::SAR
    end
  end
end
