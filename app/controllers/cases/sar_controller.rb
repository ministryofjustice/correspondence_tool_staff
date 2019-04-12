class SarCasesController < CasesController
  include CreateCase
  include NewCase

  def new
    new_case_for CorrespondenceType.sar
  end

  def create
    create_case_for_type CorrespondenceType.sar, 'sar'
  end

end
