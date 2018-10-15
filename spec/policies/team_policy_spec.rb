require 'rails_helper'

describe TeamPolicy do
  let(:responding_team) { find_or_create :foi_responding_team }
  let(:manager)         { find_or_create :disclosure_bmt_user }
  let(:responder)       { responding_team.responders.first }
  let(:approver)        { find_or_create :disclosure_specialist }

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

  permissions :business_areas_covered? do
    it { should     permit(manager,   responding_team) }
    it { should     permit(responder, responder.responding_teams.first) }
    it { should_not permit(responder, Team.first) }
    it { should_not permit(approver,  responding_team) }
  end
end
