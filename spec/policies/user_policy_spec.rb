require "rails_helper"

describe UserPolicy do
  subject { described_class }

  let(:responding_team) { create :responding_team }
  let(:manager)         { create :manager }
  let(:team_admin)      { create :team_admin }
  let(:responder)       { find_or_create :foi_responder }
  let(:approver)        { create :approver }

  permissions :destroy? do
    it { is_expected.to     permit(team_admin,  Team.first)  }
    it { is_expected.to     permit(manager,     Team.first)  }
    it { is_expected.not_to permit(responder,   Team.first) }
    it { is_expected.not_to permit(approver,    Team.first) }
  end
end
