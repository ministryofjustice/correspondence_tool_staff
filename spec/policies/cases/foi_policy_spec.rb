require 'rails_helper'

describe Case::FOIPolicy do
  subject { described_class }
  # Teams
  let(:managing_team)     { find_or_create :team_dacu }
  let(:responding_team)   { create :responding_team }
  let!(:dacu_disclosure)  { find_or_create :team_dacu_disclosure }


  # Users
  let(:manager)           { managing_team.managers.first }
  let(:responder)         { responding_team.responders.first }
  let(:press_officer)     { find_or_create :press_officer }
  let(:private_officer)   { find_or_create :private_officer }
  let(:disclosure_specialist) { approver }
  let(:responder)         { responding_team.responders.first }
  let(:approver)          { dacu_disclosure.approvers.first }

  # Cases
  let(:unassigned_case)         { create :case }
  let(:accepted_case)           { create :accepted_case,
                                        responder: responder,
                                        manager: manager }
  let(:pending_dacu_clearance_case)  { create :pending_dacu_clearance_case,
                                        approver: approver }
  let(:responded_case)          { create :responded_case,
                                        responder: responder }
  let(:closed_case)             { create :closed_case,
                                        responder: responder }
  let(:case_with_response)      { create :case_with_response,
                                        responder: responder }


  permissions :request_further_clearance? do
    it { should_not permit(responder,             accepted_case) }
    it { should     permit(manager,               accepted_case) }
    it { should     permit(manager,               case_with_response)}
    it { should_not permit(manager,               unassigned_case) }
    it { should_not permit(manager,               closed_case) }
    it { should_not permit(disclosure_specialist, accepted_case) }
    it { should_not permit(press_officer,         accepted_case) }
    it { should_not permit(private_officer,       accepted_case) }
  end

  permissions :can_request_further_clearance? do
    let(:unassigned_case_within_escalation) do
      create :case,
             creation_time: 1.business_day.ago,
             identifier: 'unassigned case within escalation deadline'
    end
    let(:unassigned_flagged_case_within_escalation) do
      create :case,
             :flagged, :dacu_disclosure,
             creation_time: 1.business_day.ago,
             identifier: 'unassigned flagged case within escalation deadline'
    end
    let(:unassigned_trigger_case_within_escalation) do
      create :case,
             :flagged_accepted, :dacu_disclosure,
             creation_time: 1.business_day.ago,
             identifier: 'unassigned trigger case within escalation deadline'
    end
    let(:unassigned_press_case_within_escalation) do
      create :case,
             :flagged_accepted, :press_office,
             creation_time: 1.business_day.ago,
             identifier: 'unassigned press case within escalation deadline'
    end
    let(:accepted_flagged_case) do
      create :accepted_case, :flagged, :dacu_disclosure
    end
    let(:accepted_trigger_case) do
      create :accepted_case, :flagged, :dacu_disclosure
    end
    let(:accepted_press_case) do
      create :accepted_case, :flagged, :press_office
    end
    let(:approved_case) { create :approved_case }

    it { should     permit(manager, unassigned_case_within_escalation) }
    it { should_not permit(manager, unassigned_flagged_case_within_escalation) }
    it { should_not permit(manager, unassigned_trigger_case_within_escalation) }
    it { should_not permit(manager, unassigned_press_case_within_escalation) }
    it { should     permit(manager, accepted_case) }
    it { should     permit(manager, accepted_flagged_case) }
    it { should     permit(manager, accepted_trigger_case) }
    it { should_not permit(manager, accepted_press_case) }
    it { should     permit(manager, pending_dacu_clearance_case) }
    it { should     permit(manager, responded_case) }
    it { should     permit(manager, approved_case) }
  end
end
