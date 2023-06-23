require "rails_helper"

describe TeamPolicy do
  subject { described_class }

  let(:responding_team) { find_or_create :foi_responding_team }
  let(:manager)         { find_or_create :disclosure_bmt_user }
  let(:responder)       { responding_team.responders.first }
  let(:other_responder) { create :responder }
  let(:approver)        { find_or_create :disclosure_specialist }

  # rubocop:disable RSpec/RepeatedExample
  permissions :can_add_new_responder? do
    it { is_expected.to     permit(manager,         responding_team) }
    it { is_expected.to     permit(responder,       responding_team) }
    it { is_expected.not_to permit(other_responder, responding_team) }
    it { is_expected.not_to permit(approver,        responding_team) }
  end

  permissions :edit? do
    it { is_expected.to     permit(manager,         Team.first) }
    it { is_expected.not_to permit(responder,       Team.first) }
    it { is_expected.not_to permit(approver,        Team.first) }
  end

  permissions :show? do
    it { is_expected.to     permit(manager,   Team.first) }
    it { is_expected.not_to permit(responder, Team.first) }
    it { is_expected.not_to permit(approver,  Team.first) }
  end

  permissions :update? do
    it { is_expected.to     permit(manager,     Team.first) }
    it { is_expected.not_to permit(responder,   Team.first) }
    it { is_expected.not_to permit(approver,    Team.first) }
  end

  permissions :business_areas_covered? do
    it { is_expected.to     permit(manager,   responding_team) }
    it { is_expected.to     permit(responder, responder.responding_teams.first) }
    it { is_expected.not_to permit(responder, Team.first) }
    it { is_expected.not_to permit(approver,  responding_team) }
  end
  # rubocop:enable RSpec/RepeatedExample
end
