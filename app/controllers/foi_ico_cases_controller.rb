class FoiIcoCasesController < CaseBaseController
  def new
    @correspondence_type_key = 'ico'
    new_method CorrespondenceType.ico
  end

  def create
    create_method CorrespondenceType.ico, 'ico'
  end
end