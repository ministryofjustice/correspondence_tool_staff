class Case::OverturnedICO::SARPolicy < Case::SARPolicy

  def new_overturned_ico?
    FeatureSet.ico.enabled? && @user.manager?
  end

end
