require 'rails_helper'

describe Case::SAR::InternalReviewPolicy do

  subject { described_class }

  let(:managing_team)         { find_or_create :team_dacu }
  let(:manager)               { managing_team.managers.first }
  let(:responding_team)       { create :responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:approver)   { dacu_disclosure.approvers.first }

  let(:sar_ir)   { 
    create(:sar_internal_review,
           managing_team: managing_team,
           responding_team: responding_team,
           approver: approver)
  }

  let(:approved_sar_ir) { 
    create(:approved_sar_internal_review,
           managing_team: managing_team,
           responding_team: responding_team,
           approver: approver) 
  }

  let(:awaiting_dispatch_approved_sar_ir) { 
    create(:approved_sar_internal_review,
           managing_team: managing_team,
           responding_team: responding_team,
           approver: approver,
           current_state: 'awaiting_dispatch') 
  }

  after(:each) do |example|
    if example.exception
      failed_checks = described_class.failed_checks rescue []
      puts "Failed CasePolicy checks: " +
           failed_checks.map(&:first).map(&:to_s).join(', ')
    end
  end

  context 'case type' do
    it 'has sar internal review as scope correspondence type' do
      type = subject::Scope.new(
        manager, 
        Case::SAR::InternalReview
      ).correspondence_type

      expect(type).to be(CorrespondenceType.sar_internal_review)
    end
  end

  context 'unapproved sar ir' do
    permissions :edit? do
      it { should_not permit(responder, sar_ir) }
      it { should     permit(manager,   sar_ir) }
      it { should_not permit(approver,  sar_ir) }
    end
  end

  context 'approved sar ir' do
    permissions :edit? do
      it { should_not permit(responder, approved_sar_ir) }
      it { should     permit(manager,   approved_sar_ir) }
      it { should     permit(approver,  approved_sar_ir) }
    end
  end

  context 'closing a case' do
    permissions :can_close_case? do
      it { should_not permit(responder, sar_ir) }
      it { should     permit(manager,   sar_ir) }
      it { should_not permit(approver,  sar_ir) }
    end

    permissions :respond_and_close? do
      it { should_not permit(responder, sar_ir) }
      it { should     permit(manager,   sar_ir) }
      it { should_not permit(approver,  sar_ir) }
    end
  end

  context 'case in awaiting_dispatch state' do
    permissions :can_respond? do
      it { should     permit(responder, awaiting_dispatch_approved_sar_ir) }
      it { should_not permit(manager,   awaiting_dispatch_approved_sar_ir) }
      it { should_not permit(approver,  awaiting_dispatch_approved_sar_ir) }
    end
  end
end
