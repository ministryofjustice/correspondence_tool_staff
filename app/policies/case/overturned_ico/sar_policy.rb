class Case::OverturnedICO::SARPolicy < Case::SARPolicy
  def new?
    @user.manager?
  end

  class Scope < Case::SARPolicy::Scope
    def correspondence_type
      CorrespondenceType.overturned_sar
    end
  end
end
