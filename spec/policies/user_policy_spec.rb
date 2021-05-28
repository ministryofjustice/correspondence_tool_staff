require 'rails_helper'

describe UserPolicy do
  let(:responding_team) { create :responding_team }
  let(:manager)         { create :manager }
  let(:team_admin)      { create :team_admin }
  let(:responder)       { find_or_create :foi_responder }
  let(:approver)        { create :approver }

  subject { described_class }

  permissions :destroy? do
    it { should     permit(team_admin,  Team.first)  }
    it { should     permit(manager,     Team.first)  }
    it { should_not permit(responder,   Team.first) }
    it { should_not permit(approver,    Team.first) }
  end
end
