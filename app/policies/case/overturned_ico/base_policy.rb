class Case::OverturnedICO::BasePolicy < Case::BasePolicy
  def new_overturned_ico?
    FeatureSet.ico.enabled? && @user.manager?
  end
end
