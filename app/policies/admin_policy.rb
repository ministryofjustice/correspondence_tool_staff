class AdminPolicy < ApplicationPolicy

  def initialize(user, team)
    @user = user
    super(user, team)
  end

  



end
