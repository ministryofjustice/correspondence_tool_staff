require "rails_helper"

RSpec.describe Case::ICO::SARPolicy do
  subject { described_class }

  let(:manager) { create :manager }

  describe Case::ICO::SARPolicy::Scope do
    let(:sar_standard_scope) { instance_spy(Case::SARPolicy::Scope) }

    before do
      allow(Case::SARPolicy::Scope)
        .to receive(:new)
              .and_return(sar_standard_scope)
    end

    it "instantiates Case::SARPolicy::Scope" do
      described_class.new(manager, Case::ICO::SAR.all).resolve

      expect(Case::SARPolicy::Scope)
        .to have_received(:new).with(manager, Case::ICO::SAR.all, nil)
    end

    it "defers to resolving with Case::SARPolicy::Scope" do
      result = described_class.new(manager, Case::ICO::SAR.all).resolve

      expect(sar_standard_scope).to have_received(:resolve)
      expect(result).to eq sar_standard_scope.resolve
    end
  end

  permissions :show? do
    it "defers to Case::SARPolicy" do
      expect_any_instance_of(Case::SARPolicy).to receive(:show?) # rubocop:disable RSpec/AnyInstance
      Pundit.policy(manager, Case::ICO::SAR).show?
    end
  end

  permissions :can_set_outcome? do
    let(:case_with_response) { create :case_with_response }
    let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }
    let(:approver) { dacu_disclosure.approvers.first }
    let(:managing_team) { find_or_create :team_dacu }
    let(:manager) { managing_team.managers.first }
    let(:responding_team) { find_or_create :foi_responding_team }
    let(:responder) { responding_team.responders.first }

    before do
      case_with_response.approving_teams << dacu_disclosure
    end

    it { is_expected.not_to permit(manager, case_with_response) }
    it { is_expected.not_to permit(responder, case_with_response) }
    it { is_expected.to permit(approver, case_with_response) }
  end
end
