require 'rails_helper'

describe TeamPolicy do
  let(:responding_team) { create :responding_team }
  let(:manager)         { create :manager }
  let(:responder)       { create :responder }
  let(:approver)        { create :approver }

  subject { described_class }

  permissions :can_add_new_responder? do
    it { should     permit(manager,   responding_team) }
    it { should_not permit(responder, responding_team) }
    it { should_not permit(approver,  responding_team) }
  end

  permissions :edit? do
    it { should     permit(manager,     Team.first)  }
    it { should_not permit(responder,   Team.first) }
    it { should_not permit(approver,    Team.first) }
  end

  permissions :show? do
    it { should     permit(manager,   Team.first)  }
    it { should_not permit(responder, Team.first) }
    it { should_not permit(approver,  Team.first) }
  end

  permissions :update? do
    it { should     permit(manager,     Team.first)  }
    it { should_not permit(responder,   Team.first) }
    it { should_not permit(approver,    Team.first) }
  end
end
