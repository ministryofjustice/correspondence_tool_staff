require "rails_helper"

RSpec.describe Case::OverturnedICO::SARPolicy do
  subject { described_class }

  let(:managing_team)         { find_or_create :team_dacu }
  let(:other_managing_team)   { create :managing_team }
  let(:manager)               { managing_team.managers.first }
  let(:responding_team)       { create :responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:disclosure_specialist) { dacu_disclosure.approvers.first }

  let(:unassigned_case)       { create :overturned_ico_sar }

  let(:manager)               { managing_team.managers.first }
  let(:other_manager)         { other_managing_team.managers.first }
  let(:responder)             { responding_team.responders.first }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_approver)   { dacu_disclosure.approvers.first }

  permissions :can_add_case? do
    it { is_expected.to     permit(manager,                 Case::OverturnedICO::SAR) }
    it { is_expected.not_to permit(disclosure_specialist,   Case::OverturnedICO::SAR) }
    it { is_expected.not_to permit(responder,               Case::OverturnedICO::SAR) }
  end

  permissions :new? do
    context "when manager" do
      it { is_expected.to permit(manager, Case::OverturnedICO::Base) }
    end

    context "when responder" do
      it { is_expected.not_to permit(responder, Case::OverturnedICO::Base) }
    end

    context "when approver" do
      it { is_expected.not_to permit(disclosure_specialist, Case::OverturnedICO::Base) }
    end
  end

  permissions :show? do
    context "when unassigned case" do
      it { is_expected.to     permit(manager,               unassigned_case) }
      it { is_expected.not_to permit(responder,             unassigned_case) }
      it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
    end

    context "when linked case" do
      let!(:linked_case) do
        create(:closed_sar, responding_team:).tap do |kase|
          unassigned_case.related_cases << kase
        end
      end

      it { is_expected.not_to permit(responder,             unassigned_case) }
      it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
    end
  end

  permissions :new_case_link? do
    it { is_expected.to     permit(manager,             unassigned_case) }
    it { is_expected.not_to permit(other_manager,       unassigned_case) }
    it { is_expected.not_to permit(responder,           unassigned_case) }
    it { is_expected.not_to permit(press_officer,       unassigned_case) }
    it { is_expected.not_to permit(private_officer,     unassigned_case) }
    it { is_expected.not_to permit(disclosure_approver, unassigned_case) }
  end
end
