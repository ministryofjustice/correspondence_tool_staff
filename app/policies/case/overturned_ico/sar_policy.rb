class Case::OverturnedICO::SARPolicy < Case::SARPolicy
  def new?
    FeatureSet.ico.enabled? && @user.manager?
  end
end
