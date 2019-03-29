class FoiStandardCasesController < CaseBaseController

  def new
    @correspondence_type_key = 'foi'
    new_method CorrespondenceType.foi
  end

  def create
    create_method CorrespondenceType.foi, 'foi'
  end
end