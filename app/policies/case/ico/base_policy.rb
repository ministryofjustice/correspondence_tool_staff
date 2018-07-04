class Case::ICO::BasePolicy < Case::BasePolicy
  def show?
    defer_to_existing_policy(Case::FOI::StandardPolicy, :show?)
  end
end
