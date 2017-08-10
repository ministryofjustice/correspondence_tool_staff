require 'rails_helper'


def fpermissions(*list, &block)
  fdescribe(list.to_sentence, permissions: list, caller: caller) do
    instance_eval(&block)
  end
end


def xpermissions(*list, &block)
  xdescribe(list.to_sentence, permissions: list, caller: caller) do
    instance_eval(&block)
  end
end


describe CasePolicy do
  subject { described_class }

  let(:managing_team)     { find_or_create :team_dacu }
  let(:manager)           { managing_team.managers.first }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:coworker)          { create :responder,
                                   responding_teams: [responding_team] }
  let(:another_responder) { create :responder}
  let!(:dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:approver)          { dacu_disclosure.approvers.first }
  let(:disclosure_specialist) { approver }
  let(:another_disclosure_specialist) { create :disclosure_specialist }
  let(:press_officer)     { find_or_create :press_officer }
  let(:private_officer)   { find_or_create :private_officer }
  let(:co_approver)       { create :approver, approving_team: dacu_disclosure }

  let(:new_case)                { create :case }
  let(:accepted_case)           { create :accepted_case,
                                         responder: responder,
                                         manager: manager }
  let(:flagged_accepted_case)   { create :accepted_case, :flagged,
                                          responder: responder,
                                          manager: manager }
  let(:assigned_case)           { create :assigned_case,
                                    responding_team: responding_team }
  let(:assigned_flagged_case)   { create :assigned_case, :flagged,
                                         approving_team: dacu_disclosure}
  let(:assigned_trigger_case)   { create :assigned_case, :flagged_accepted,
                                         approver: approver }
  let(:rejected_case)           { create :rejected_case,
                                         responding_team: responding_team }
  let(:unassigned_case)         { new_case }
  let(:unassigned_flagged_case) { create :case, :flagged,
                                         approving_team: dacu_disclosure }
  let(:unassigned_trigger_case) { create :case, :flagged_accepted,
                                         approving_team: dacu_disclosure }
  let(:case_with_response)      { create :case_with_response,
                                         responder: responder }
  let(:case_with_response_flagged) { create :case_with_response, :flagged,
                                            responder: responder }
  let(:case_with_response_trigger) { create :case_with_response,
                                            :flagged_accepted,
                                            responder: responder }
  let(:responded_case)          { create :responded_case,
                                         responder: responder }
  let(:closed_case)             { create :closed_case,
                                         responder: responder }

  let(:pending_dacu_clearance_case)  { create :pending_dacu_clearance_case,
                                              approver: approver }
  let(:pending_press_clearance_case) { create :pending_press_clearance_case,
                                              press_officer: press_officer }
  let(:pending_private_clearance_case) { create :pending_private_clearance_case,
                                                private_officer: private_officer }
  let(:awaiting_dispatch_case)       { create :case_with_response,
                                              responding_team: responding_team,
                                              responder: responder }
  let(:awaiting_dispatch_flagged_case)  { create :case_with_response, :flagged, responding_team: responding_team, responder: responder }


  permissions :can_view_attachments? do
    context 'flagged cases' do
      it { should permit(manager,            awaiting_dispatch_flagged_case)  }
      it { should permit(responder,          awaiting_dispatch_flagged_case)  }
      it { should permit(another_responder,  awaiting_dispatch_flagged_case)  }
      it { should permit(approver,           awaiting_dispatch_flagged_case)  }
      it { should permit(co_approver,        awaiting_dispatch_flagged_case)  }
    end

    context 'unflagged cases' do
      context 'in awaiting_dispatch state' do
        it { should     permit(responder,         awaiting_dispatch_case) }
        it { should     permit(coworker,          awaiting_dispatch_case) }
        it { should_not permit(manager,           awaiting_dispatch_case) }
        it { should_not permit(approver,          awaiting_dispatch_case) }
      end

      context 'in other states' do
        it { should permit(manager,            responded_case) }
        it { should permit(responder,          responded_case)  }
        it { should permit(another_responder,  responded_case)  }
        it { should permit(approver,           responded_case)  }
        it { should permit(co_approver,        responded_case)  }
      end
    end
  end

  after(:each) do |example|
    if example.exception
      failed_checks = CasePolicy.failed_checks rescue []
      puts "Failed CasePolicy checks: #{failed_checks.map(&:first).map(&:to_s).join(', ')}"
    end
  end

  permissions :can_accept_or_reject_approver_assignment? do
    it { should_not permit(manager,           unassigned_flagged_case) }
    it { should_not permit(responder,         unassigned_flagged_case) }
    it { should_not permit(another_responder, unassigned_flagged_case) }
    it { should     permit(approver,          unassigned_flagged_case) }
    it { should_not permit(approver,          unassigned_trigger_case) }
  end

  permissions :can_unaccept_approval_assignment? do
    it { should     permit(approver,  pending_dacu_clearance_case) }
    it { should_not permit(manager,   pending_dacu_clearance_case) }
    it { should_not permit(responder, pending_dacu_clearance_case) }
  end

  describe  do
    permissions :can_take_on_for_approval? do
      it { should_not   permit(approver,          pending_dacu_clearance_case) }
      it { should       permit(approver,          flagged_accepted_case) }
      it { should_not   permit(manager,           pending_dacu_clearance_case) }
      it { should_not   permit(responder,         pending_dacu_clearance_case) }
    end
  end

  permissions :can_accept_or_reject_responder_assignment? do
    it { should_not permit(manager,           assigned_case) }
    it { should     permit(responder,         assigned_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(approver,          assigned_case) }
  end

  permissions :can_download_stats? do
    it { should     permit(manager,           assigned_case) }
    it { should_not permit(responder,         assigned_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(approver,          assigned_case) }
  end

  permissions :can_add_attachment? do
    context 'in drafting state' do
      it { should_not permit(manager,           accepted_case) }
      it { should     permit(responder,         accepted_case) }
      it { should     permit(coworker,          accepted_case) }
      it { should_not permit(another_responder, accepted_case) }
    end

    context 'in awaiting_dispatch state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should_not permit(responder,         flagged_accepted_case) }
        it { should_not permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
      end

      context 'unflagged_case' do

        it { should_not permit(manager,           case_with_response) }
        it { should     permit(responder,         case_with_response) }
        it { should     permit(coworker,          case_with_response) }
        it { should_not permit(another_responder, case_with_response) }
      end
    end
  end

  permissions :can_add_attachment_to_flagged_and_unflagged_cases? do
    context 'in awaiting dispatch_state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should     permit(responder,         flagged_accepted_case) }
        it { should     permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
        it { should_not permit(approver,          flagged_accepted_case) }
      end

      context 'unflagged case' do
        it { should_not permit(manager,           accepted_case) }
        it { should     permit(responder,         accepted_case) }
        it { should     permit(coworker,          accepted_case) }
        it { should_not permit(another_responder, accepted_case) }
        it { should_not permit(approver,          accepted_case) }
      end

      context 'pending clearance case' do
        it { should_not permit(manager,           pending_dacu_clearance_case) }
        it { should_not permit(responder,         pending_dacu_clearance_case) }
        it { should_not permit(coworker,          pending_dacu_clearance_case) }
        it { should_not permit(another_responder, pending_dacu_clearance_case) }
        it { should     permit(approver,          pending_dacu_clearance_case) }
      end
    end
  end

  permissions :can_add_case? do
    it { should_not permit(responder, new_case) }
    it { should     permit(manager,   new_case) }
  end

  permissions :can_assign_case? do
    it { should_not permit(responder, new_case) }
    it { should     permit(manager,   new_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(responder, assigned_case) }
  end

  permissions :can_close_case? do
    it { should_not permit(responder, responded_case) }
    it { should     permit(manager,   responded_case) }
  end

  permissions :can_flag_for_clearance? do
    it { should_not permit(responder, assigned_case) }
    it { should     permit(manager,   assigned_case) }
    it { should     permit(approver,  assigned_case) }
  end

  permissions :can_remove_attachment? do
    context 'case is still being drafted' do
      it { should     permit(responder,         case_with_response) }
      it { should_not permit(another_responder, case_with_response) }
      it { should_not permit(manager,           case_with_response) }
    end

    context 'case has been marked as responded' do
      it { should_not permit(another_responder, responded_case) }
      it { should_not permit(manager,           responded_case) }
    end
  end

  permissions :can_respond? do
    it { should_not permit(manager,           case_with_response) }
    it { should     permit(responder,         case_with_response) }
    it { should     permit(coworker,          case_with_response) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(responder,         accepted_case) }
    it { should_not permit(coworker,          accepted_case) }
  end

  context 'unflag for clearance event' do
    let(:awaiting_responder_case)           { create :awaiting_responder_case }
    let(:awaiting_responder_flagged_case)   { create :awaiting_responder_case, :flagged }
    let(:drafting_case)                     { create :accepted_case }
    let(:drafting_flagged_case)             { create :accepted_case, :flagged }
    let(:awaiting_dispatch_case)            { create :case_with_response }
    let(:awaiting_dispatch_flagged_case)    { create :case_with_response, :flagged }
    let(:pending_dacu_clearance_press_case) { create :pending_dacu_clearance_case_flagged_for_press }

    permissions :unflag_for_clearance_from_unassigned_to_unassigned? do
      it { should     permit(disclosure_specialist, unassigned_flagged_case) }
      it { should     permit(manager,               unassigned_flagged_case) }
      it { should_not permit(responder,             unassigned_flagged_case) }
      it { should_not permit(manager,               unassigned_case) }
    end

    permissions :unflag_for_clearance_from_awaiting_responder_to_awaiting_responder? do
      it { should     permit(disclosure_specialist, awaiting_responder_flagged_case) }
      it { should     permit(manager,               awaiting_responder_flagged_case) }
      it { should_not permit(responder,             awaiting_responder_flagged_case) }
      it { should_not permit(manager,               awaiting_responder_case) }
    end

    permissions :unflag_for_clearance_from_drafting_to_drafting? do
      it { should     permit(disclosure_specialist, drafting_flagged_case) }
      it { should     permit(manager,               drafting_flagged_case) }
      it { should_not permit(responder,             drafting_flagged_case) }
      it { should_not permit(manager,               drafting_case) }
    end

    permissions :unflag_for_clearance_from_awaiting_dispatch_to_awaiting_dispatch? do
      it { should     permit(disclosure_specialist, awaiting_dispatch_flagged_case) }
      it { should     permit(manager,               awaiting_dispatch_flagged_case) }
      it { should_not permit(responder,             awaiting_dispatch_flagged_case) }
      it { should_not permit(manager,               awaiting_dispatch_case) }
    end

    permissions :unflag_for_clearance_from_pending_dacu_clearance_to_awaiting_dispatch? do
      context 'flagged for dacu disclosure only' do
        it { should     permit(disclosure_specialist, pending_dacu_clearance_case) }
        it { should     permit(manager,               pending_dacu_clearance_case) }
        it { should_not permit(responder,             pending_dacu_clearance_case) }
      end

      context 'flagged for dacu disclosure and press office' do
        it { should_not permit(manager,               pending_dacu_clearance_press_case) }
        it { should_not permit(disclosure_specialist, pending_dacu_clearance_press_case) }
        it { should_not permit(responder,             pending_dacu_clearance_press_case) }
        it { should_not permit(press_officer,         pending_dacu_clearance_press_case) }
      end
    end

    permissions :unflag_for_clearance_from_pending_dacu_clearance_to_pending_dacu_clearance? do
      context 'flagged for dacu disclosure only' do
        it { should_not permit(disclosure_specialist, pending_dacu_clearance_case) }
        it { should_not permit(manager,               pending_dacu_clearance_case) }
        it { should_not permit(responder,             pending_dacu_clearance_case) }
      end
      context 'flagged for dacu disclosure and press office' do
        it { should_not permit(manager,               pending_dacu_clearance_press_case) }
        it { should_not permit(disclosure_specialist, pending_dacu_clearance_press_case) }
        it { should_not permit(responder,             pending_dacu_clearance_press_case) }
        it { should     permit(press_officer,         pending_dacu_clearance_press_case) }
        it { should_not permit(private_officer,       pending_dacu_clearance_press_case) }
      end
    end
  end

  permissions :assignments_reassign_user? do
    context 'unflagged case' do
      it { should     permit(responder, accepted_case) }
      it { should_not permit(approver, accepted_case) }
    end

    context 'flagged by not yet taken by approver' do
      it { should  permit(responder, flagged_accepted_case) }
      it 'does not permit' do
        expect(flagged_accepted_case.requires_clearance?).to be true
        expect(flagged_accepted_case.approvers).to be_empty
        should_not permit(approver, flagged_accepted_case)
      end
    end

    context 'flagged case taken on' do
      it 'does not permit' do
        should_not permit(responder , pending_dacu_clearance_case)
      end

      it 'does permit' do
        expect(pending_dacu_clearance_case.requires_clearance?).to be true
        expect(pending_dacu_clearance_case.approvers.first)
          .to be_instance_of(User)
        should permit(pending_dacu_clearance_case.approvers.first,
                          pending_dacu_clearance_case)
      end
    end

    context 'case is being finalised' do
      it { should_not permit(responder, responded_case)}
      it { should_not permit(coworker , responded_case)}
      it { should_not permit(approver , responded_case)}
      it { should_not permit(approver , awaiting_dispatch_flagged_case)}
    end

    context 'case is closed' do
      it {should_not permit(responder,         closed_case)}
      it {should_not permit(coworker,          closed_case)}
      it {should_not permit(another_responder, closed_case)}
      it {should_not permit(approver,          closed_case)}
      it {should_not permit(co_approver,       closed_case)}
    end

    context 'managers should not need to assign to another team member' do
      it { should_not permit(manager, assigned_case )}
      it { should_not permit(manager, assigned_trigger_case )}
      it { should_not permit(manager, closed_case )}
    end

  end

  permissions :can_approve_or_escalate_case? do
    it { should_not permit(disclosure_specialist, case_with_response) }
    it { should     permit(disclosure_specialist, pending_dacu_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_press_clearance_case) }
    it { should_not permit(press_officer,         case_with_response) }
    it { should_not permit(press_officer,         pending_dacu_clearance_case) }
    it { should     permit(press_officer,         pending_press_clearance_case) }
  end

  permissions :can_view_case_details? do
    it { should     permit(manager,           new_case) }
    it { should     permit(manager,           assigned_case) }
    it { should     permit(manager,           accepted_case) }
    it { should     permit(manager,           rejected_case) }
    it { should     permit(manager,           case_with_response) }
    it { should     permit(manager,           responded_case) }
    it { should     permit(manager,           closed_case) }
    it { should_not permit(responder,         new_case) }
    it { should     permit(responder,         assigned_case) }
    it { should     permit(responder,         accepted_case) }
    it { should_not permit(responder,         rejected_case) }
    it { should     permit(responder,         case_with_response) }
    it { should     permit(responder,         responded_case) }
    it { should     permit(responder,         closed_case) }
    it { should_not permit(coworker,          new_case) }
    it { should     permit(coworker,          assigned_case) }
    it { should     permit(coworker,          accepted_case) }
    it { should_not permit(coworker,          rejected_case) }
    it { should     permit(coworker,          case_with_response) }
    it { should     permit(coworker,          responded_case) }
    it { should     permit(coworker,          closed_case) }
    it { should_not permit(another_responder, new_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(another_responder, rejected_case) }
    it { should_not permit(another_responder, accepted_case) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(another_responder, responded_case) }
    it { should_not permit(another_responder, closed_case) }
    it { should     permit(approver,          assigned_flagged_case) }
    it { should     permit(approver,          assigned_trigger_case) }
    it { should     permit(approver,          assigned_case) }
    it { should     permit(approver,          assigned_case) }
  end

  permissions :can_add_message_to_case? do
    let(:flagged_case_responder)  { pending_dacu_clearance_case.responder }
    let(:other_responder) { create :responder }

    context 'closed case' do
      it { should_not permit(manager,     closed_case) }
      it { should_not permit(approver,    closed_case) }
      it { should_not permit(responder,   closed_case) }
    end

    context 'open case' do
      it { should     permit(manager,                   pending_dacu_clearance_case) }
      it { should     permit(approver,                  pending_dacu_clearance_case) }
      it { should     permit(flagged_case_responder,    pending_dacu_clearance_case) }
      it { should_not permit(other_responder,           pending_dacu_clearance_case) }
    end
  end

  permissions :execute_response_approval? do
    let(:flagged_case_responder)  { pending_dacu_clearance_case.responder }

    it { should_not permit(manager,   pending_dacu_clearance_case) }
    it { should     permit(approver,  pending_dacu_clearance_case) }
    it { should_not permit(responder, pending_dacu_clearance_case) }
  end

  permissions :new_response_upload? do
    it { should_not permit(manager,                accepted_case) }
    it { should     permit(responder,              accepted_case) }
    it { should_not permit(disclosure_specialist,  accepted_case) }
    it { should_not permit(press_officer,          accepted_case) }
    it { should_not permit(manager,                pending_dacu_clearance_case) }
    it { should_not permit(responder,              pending_dacu_clearance_case) }
    it { should     permit(disclosure_specialist,  pending_dacu_clearance_case) }
    it { should_not permit(press_officer,          pending_dacu_clearance_case) }
    it { should_not permit(manager,                pending_press_clearance_case) }
    it { should_not permit(responder,              pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist,  pending_press_clearance_case) }
    it { should     permit(press_officer,          pending_press_clearance_case) }
  end

  permissions :upload_responses? do
    it { should_not permit(manager,                accepted_case) }
    it { should     permit(responder,              accepted_case) }
    it { should_not permit(disclosure_specialist,  accepted_case) }
    it { should_not permit(press_officer,          accepted_case) }
    it { should_not permit(manager,                pending_dacu_clearance_case) }
    it { should_not permit(responder,              pending_dacu_clearance_case) }
    it { should     permit(disclosure_specialist,  pending_dacu_clearance_case) }
    it { should_not permit(press_officer,          pending_dacu_clearance_case) }
    it { should_not permit(manager,                pending_press_clearance_case) }
    it { should_not permit(responder,              pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist,  pending_press_clearance_case) }
    it { should     permit(press_officer,          pending_press_clearance_case) }
  end

  permissions :upload_response_and_return_for_redraft_from_pending_dacu_clearance_to_drafting? do
    it { should_not permit(manager,                pending_dacu_clearance_case) }
    it { should_not permit(responder,              pending_dacu_clearance_case) }
    it { should     permit(disclosure_specialist,  pending_dacu_clearance_case) }
    it { should_not permit(press_officer,          pending_dacu_clearance_case) }
  end

  permissions :approve_from_pending_dacu_clearance_to_awaiting_dispatch? do
    it { should_not permit(responder,             pending_dacu_clearance_case) }
    it { should     permit(disclosure_specialist, pending_dacu_clearance_case) }
    it { should_not permit(press_officer,         pending_dacu_clearance_case) }
    it { should_not permit(private_officer,       pending_dacu_clearance_case) }
  end

  permissions :approve_from_pending_dacu_clearance_to_pending_press_office_clearance? do
    let(:kase) { create :pending_dacu_clearance_case, :press_office }
    it { should_not permit(responder,             kase) }
    it { should     permit(disclosure_specialist, kase) }
    it { should_not permit(press_officer,         kase) }
    it { should_not permit(private_officer,       kase) }
  end

  permissions :approve_from_pending_press_office_clearance_to_awaiting_dispatch? do
    it { should_not permit(responder,             pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_press_clearance_case) }
    it { should     permit(press_officer,         pending_press_clearance_case) }
    it { should_not permit(private_officer,       pending_press_clearance_case) }
  end

  permissions :approve_from_pending_press_office_clearance_to_pending_private_office_clearance? do
    let(:kase) { create :pending_press_clearance_case, :private_office }
    it { should_not permit(responder,             kase) }
    it { should_not permit(disclosure_specialist, kase) }
    it { should     permit(press_officer,         kase) }
    it { should_not permit(private_officer,       kase) }
  end

  permissions :approve_from_pending_private_office_clearance_to_awaiting_dispatch? do
    it { should_not permit(responder,             pending_private_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_private_clearance_case) }
    it { should_not permit(press_officer,         pending_private_clearance_case) }
    it { should     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :request_amends? do
    it { should_not permit(responder,             pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_press_clearance_case) }
    it { should     permit(press_officer,         pending_press_clearance_case) }
    it { should_not permit(private_officer,       pending_press_clearance_case) }
    it { should_not permit(responder,             pending_private_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_private_clearance_case) }
    it { should_not permit(press_officer,         pending_private_clearance_case) }
    it { should     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :execute_request_amends? do
    it { should_not permit(responder,             pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_press_clearance_case) }
    it { should     permit(press_officer,         pending_press_clearance_case) }
    it { should_not permit(private_officer,       pending_press_clearance_case) }
    it { should_not permit(responder,             pending_private_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_private_clearance_case) }
    it { should_not permit(press_officer,         pending_private_clearance_case) }
    it { should     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :request_amends_from_pending_press_office_clearance_to_pending_dacu_clearance? do
    it { should_not permit(responder,             pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_press_clearance_case) }
    it { should     permit(press_officer,         pending_press_clearance_case) }
    it { should_not permit(private_officer,       pending_press_clearance_case) }
  end

  permissions :request_amends_from_pending_private_office_clearance_to_pending_dacu_clearance? do
    it { should_not permit(responder,             pending_private_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_private_clearance_case) }
    it { should_not permit(press_officer,         pending_private_clearance_case) }
    it { should     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :add_response_to_flagged_case_from_drafting_to_pending_dacu_clearance? do
    it { should     permit(responder,             case_with_response_trigger) }
    it { should     permit(responder,             case_with_response_flagged) }
    it { should     permit(coworker,              case_with_response_trigger) }
    it { should_not permit(another_responder,     case_with_response_trigger) }
    it { should_not permit(responder,             case_with_response) }
    it { should_not permit(disclosure_specialist, case_with_response_trigger) }
    it { should_not permit(press_officer,         case_with_response_trigger) }
    it { should_not permit(private_officer,       case_with_response_trigger) }
  end

  describe 'case scope policy' do
    let(:existing_cases) do
      [
        unassigned_case,
        assigned_case,
        accepted_case,
        rejected_case,
        case_with_response,
        responded_case,
        closed_case,
      ]
    end

    it 'for managers - returns all cases' do
      existing_cases
      manager_scope = described_class::Scope.new(manager, Case.all).resolve
      expect(manager_scope).to match_array(existing_cases)
    end

    it 'for responders - returns only their cases' do
      existing_cases
      responder_scope = described_class::Scope.new(responder, Case.all).resolve
      expect(responder_scope).to match_array([assigned_case, accepted_case, case_with_response, responded_case, closed_case])
    end

    it 'for approvers - returns all cases' do
      existing_cases
      approver_scope = described_class::Scope.new(approver, Case.all).resolve
      expect(approver_scope).to match_array(existing_cases)
    end
  end
end
