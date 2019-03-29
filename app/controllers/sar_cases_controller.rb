class SarCasesController < CaseBaseController

  def new
    new_method CorrespondenceType.sar
  end

  def create
    create_method CorrespondenceType.sar, 'sar'
  end

end
