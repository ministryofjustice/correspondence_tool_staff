require "rails_helper"

describe Case::SAR::InternalReviewPolicy do
  subject { described_class }

  let(:managing_team)         { find_or_create :team_dacu }
  let(:manager)               { managing_team.managers.first }
  let(:responding_team)       { create :responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:approver) { dacu_disclosure.approvers.first }

  let(:sar_ir) do
    create(:sar_internal_review,
           managing_team:,
           responding_team:,
           approver:)
  end

  let(:approved_sar_ir) do
    create(:approved_sar_internal_review,
           managing_team:,
           responding_team:,
           approver:)
  end

  let(:awaiting_dispatch_approved_sar_ir) do
    create(:approved_sar_internal_review,
           managing_team:,
           responding_team:,
           approver:,
           current_state: "awaiting_dispatch")
  end

  after do |example|
    if example.exception
      failed_checks = begin
        described_class.failed_checks
      rescue StandardError
        []
      end
      Rails.logger.debug "Failed CasePolicy checks: #{failed_checks.map(&:first).map(&:to_s).join(', ')}"
    end
  end

  describe "case type" do
    it "has sar internal review as scope correspondence type" do
      type = described_class::Scope.new(
        manager,
        Case::SAR::InternalReview,
      ).correspondence_type

      expect(type).to be(CorrespondenceType.sar_internal_review)
    end
  end

  context "when unapproved sar ir" do
    permissions :edit? do
      it { is_expected.not_to permit(responder, sar_ir) }
      it { is_expected.to     permit(manager,   sar_ir) }
      it { is_expected.not_to permit(approver,  sar_ir) }
    end
  end

  context "when approved sar ir" do
    permissions :edit? do
      it { is_expected.not_to permit(responder, approved_sar_ir) }
      it { is_expected.to     permit(manager,   approved_sar_ir) }
      it { is_expected.to     permit(approver,  approved_sar_ir) }
    end
  end

  # rubocop:disable RSpec/RepeatedExample
  context "when closing a case" do
    permissions :can_close_case? do
      it { is_expected.not_to permit(responder, sar_ir) }
      it { is_expected.to     permit(manager,   sar_ir) }
      it { is_expected.not_to permit(approver,  sar_ir) }
    end

    permissions :respond_and_close? do
      it { is_expected.not_to permit(responder, sar_ir) }
      it { is_expected.to     permit(manager,   sar_ir) }
      it { is_expected.not_to permit(approver,  sar_ir) }
    end
  end
  # rubocop:enable RSpec/RepeatedExample

  context "when case in awaiting_dispatch state" do
    permissions :can_respond? do
      it { is_expected.to     permit(responder, awaiting_dispatch_approved_sar_ir) }
      it { is_expected.not_to permit(manager,   awaiting_dispatch_approved_sar_ir) }
      it { is_expected.not_to permit(approver,  awaiting_dispatch_approved_sar_ir) }
    end
  end
end
