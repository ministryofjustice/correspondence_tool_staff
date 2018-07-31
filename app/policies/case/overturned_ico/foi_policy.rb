class Case::OverturnedICO::FOIPolicy < Case::FOI::StandardPolicy

  def new_overturned_ico?
    FeatureSet.ico.enabled? && @user.manager?
  end

end
