class FoiIcoCasesController < CasesController
  include CreateCase

  def new
    @correspondence_type_key = 'ico'
    new_case_for CorrespondenceType.ico
  end

  def create
    create_case_for_type CorrespondenceType.ico, 'ico'
  end
end