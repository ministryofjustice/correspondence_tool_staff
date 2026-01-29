require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll, RSpec/RepeatedExample
describe Case::BasePolicy do
  subject { described_class }

  before(:all) do
    @managing_team                 = find_or_create :team_dacu
    @manager                       = @managing_team.managers.first
    @responding_team               = find_or_create :foi_responding_team
    @responder                     = @responding_team.responders.first
    @coworker                      = create :responder,
                                            responding_teams: [@responding_team]
    @another_responder             = create :responder
    @dacu_disclosure               = find_or_create :team_dacu_disclosure
    @approver                      = @dacu_disclosure.approvers.first
    @disclosure_specialist         = @approver
    @another_disclosure_specialist = find_or_create :disclosure_specialist
    @press_officer                 = find_or_create :press_officer
    @press_office                  = find_or_create :team_press_office
    @another_press_officer         = create :approver, approving_team: @press_office
    @private_officer               = find_or_create :private_officer
    @co_approver                   = create :approver,
                                            approving_team: @dacu_disclosure
    @branston_user                 = create :branston_user

    @new_case                   = create :case
    @accepted_case              = create :accepted_case
    @flagged_accepted_case      = create :accepted_case, :flagged
    @assigned_case              = create :assigned_case
    @assigned_flagged_case      = create :assigned_case, :flagged
    @assigned_trigger_case      = create :assigned_case, :flagged_accepted
    @rejected_case              = create :rejected_case
    @unassigned_case            = @new_case
    @unassigned_flagged_case    = create :case, :flagged
    @unassigned_trigger_case    = create :case, :flagged_accepted
    @case_with_response         = create :case_with_response
    @case_with_response_flagged = create :case_with_response, :flagged
    @case_with_response_trigger = create :case_with_response, :flagged_accepted
    @responded_case             = create :responded_case
    @closed_case                = create :closed_case

    @awaiting_responder_case         = create :awaiting_responder_case
    @awaiting_responder_flagged_case = create :awaiting_responder_case, :flagged

    @pending_dacu_clearance_case    = create :pending_dacu_clearance_case,
                                             responder: @responder,
                                             approver: @approver
    @pending_press_clearance_case   = create :pending_press_clearance_case,
                                             press_officer: @press_officer
    @pending_private_clearance_case = create :pending_private_clearance_case,
                                             private_officer: @private_officer
    @awaiting_dispatch_case         = create :case_with_response,
                                             responding_team: @responding_team,
                                             responder: @responder
    @awaiting_dispatch_flagged_case = create :case_with_response,
                                             :flagged,
                                             responding_team: @responding_team,
                                             responder: @responder
    @drafting_trigger_case          = create :case_being_drafted,
                                             :flagged_accepted,
                                             approver: @approver
    @press_flagged_case             = create :assigned_case,
                                             :flagged_accepted,
                                             :press_office
    @redrafting_case                = create :redrafting_case,
                                             :flagged_accepted,
                                             :press_office,
                                             approving_team: @dacu_disclosure,
                                             approver: @disclosure_specialist,
                                             responder: @responder
    @offender_sar_case             = create :offender_sar_case
    @offender_sar_complaint        = create :offender_sar_complaint

    @pending_dacu_clearance_press_case =
      create :pending_dacu_clearance_case_flagged_for_press,
             approver: @approver
    @pending_press_private_clearance_case =
      create :pending_press_clearance_case, :private_office,
             press_officer: @press_officer

    @responder.reload
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  let(:managing_team)     { @managing_team }
  let(:manager)           { @manager }
  let(:responding_team)   { @responding_team }
  let(:responder)         { @responder }
  let(:coworker)          { @coworker }
  let(:another_responder) { @another_responder }
  let(:approver)          { @approver }
  let(:disclosure_specialist) { @disclosure_specialist }
  let(:another_disclosure_specialist) { @another_disclosure_specialist }
  let(:press_officer) { @press_officer }
  let(:another_press_officer) { @another_press_officer }
  let(:private_officer)   { @private_officer }
  let(:co_approver)       { @co_approver }
  let(:branston_user)     { @branston_user }

  let(:new_case)                { @new_case }
  let(:accepted_case)           { @accepted_case }
  let(:flagged_accepted_case)   { @flagged_accepted_case }
  let(:assigned_case)           { @assigned_case }
  let(:assigned_flagged_case)   { @assigned_flagged_case }
  let(:assigned_trigger_case)   { @assigned_trigger_case }
  let(:rejected_case)           { @rejected_case }
  let(:unassigned_case)         { @unassigned_case }
  let(:unassigned_flagged_case) { @unassigned_flagged_case }
  let(:unassigned_trigger_case) { @unassigned_trigger_case }
  let(:unassigned_flagged_press_private_case) { @unassigned_flagged_press_private_case }
  let(:case_with_response) { @case_with_response }
  let(:case_with_response_flagged) { @case_with_response_flagged }
  let(:case_with_response_trigger) { @case_with_response_trigger }
  let(:responded_case)          { @responded_case }
  let(:closed_case)             { @closed_case }

  let(:awaiting_responder_case)         { @awaiting_responder_case }
  let(:awaiting_responder_flagged_case) { @awaiting_responder_flagged_case }

  let(:pending_dacu_clearance_case)  { @pending_dacu_clearance_case }
  let(:pending_press_clearance_case) { @pending_press_clearance_case }
  let(:pending_private_clearance_case) { @pending_private_clearance_case }
  let(:awaiting_dispatch_case) { @awaiting_dispatch_case }
  let(:awaiting_dispatch_flagged_case) { @awaiting_dispatch_flagged_case }

  let(:drafting_trigger_case) { @drafting_trigger_case }
  let(:press_flagged_case) { @press_flagged_case }
  let(:redrafting_case)    { @redrafting_case }

  let(:pending_dacu_clearance_press_case) { @pending_dacu_clearance_press_case }
  let(:pending_press_private_clearance_case) { @pending_press_private_clearance_case }

  let(:offender_sar_case) { @offender_sar_case }
  let(:offender_sar_complaint) { @offender_sar_complaint }

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

  describe ".new" do
    context "when initialized with old style" do
      it "instantiates the policy using positional parameters" do
        policy = described_class.new(manager, accepted_case)
        expect(policy.user).to eq manager
        expect(policy.case).to eq accepted_case
      end
    end

    context "when initialized with new style" do
      it "instantiates the policy using named parameters" do
        policy = described_class.new(user: manager, kase: accepted_case)
        expect(policy.user).to eq manager
        expect(policy.case).to eq accepted_case
      end
    end
  end

  permissions :can_view_attachments? do
    context "when flagged cases" do
      it { is_expected.to permit(manager,            awaiting_dispatch_flagged_case)  }
      it { is_expected.to permit(responder,          awaiting_dispatch_flagged_case)  }
      it { is_expected.to permit(another_responder,  awaiting_dispatch_flagged_case)  }
      it { is_expected.to permit(approver,           awaiting_dispatch_flagged_case)  }
      it { is_expected.to permit(co_approver,        awaiting_dispatch_flagged_case)  }
    end

    context "when unflagged cases" do
      context "and in awaiting_dispatch state" do
        it { is_expected.to     permit(responder,         awaiting_dispatch_case) }
        it { is_expected.to     permit(coworker,          awaiting_dispatch_case) }
        it { is_expected.not_to permit(manager,           awaiting_dispatch_case) }
        it { is_expected.not_to permit(approver,          awaiting_dispatch_case) }
      end

      context "and in other states" do
        it { is_expected.to permit(manager,            responded_case) }
        it { is_expected.to permit(responder,          responded_case)  }
        it { is_expected.to permit(another_responder,  responded_case)  }
        it { is_expected.to permit(approver,           responded_case)  }
        it { is_expected.to permit(co_approver,        responded_case)  }
      end
    end
  end

  permissions :can_accept_or_reject_approver_assignment? do
    it { is_expected.not_to permit(manager,           unassigned_flagged_case) }
    it { is_expected.not_to permit(responder,         unassigned_flagged_case) }
    it { is_expected.not_to permit(another_responder, unassigned_flagged_case) }
    it { is_expected.to     permit(approver,          unassigned_flagged_case) }
    it { is_expected.not_to permit(approver,          unassigned_trigger_case) }
  end

  permissions :can_unaccept_approval_assignment? do
    it { is_expected.not_to permit(manager,               unassigned_trigger_case) }
    it { is_expected.to     permit(disclosure_specialist, unassigned_trigger_case) }
    it { is_expected.not_to permit(press_officer,         unassigned_trigger_case) }
    it { is_expected.not_to permit(private_officer,       unassigned_trigger_case) }
    it { is_expected.not_to permit(responder,             unassigned_trigger_case) }
    it { is_expected.not_to permit(manager,               unassigned_flagged_case) }
    it { is_expected.not_to permit(disclosure_specialist, unassigned_flagged_case) }
    it { is_expected.not_to permit(press_officer,         unassigned_flagged_case) }
    it { is_expected.not_to permit(private_officer,       unassigned_flagged_case) }
    it { is_expected.not_to permit(responder,             unassigned_flagged_case) }
    it { is_expected.to     permit(disclosure_specialist, pending_dacu_clearance_case) }
    it { is_expected.not_to permit(press_officer,         pending_dacu_clearance_case) }
    it { is_expected.to     permit(approver,              pending_dacu_clearance_case) }
    it { is_expected.not_to permit(manager,               pending_dacu_clearance_case) }
    it { is_expected.not_to permit(responder,             pending_dacu_clearance_case) }
  end

  permissions :can_take_on_for_approval? do
    it { is_expected.not_to   permit(approver,          pending_dacu_clearance_case) }
    it { is_expected.to       permit(approver,          accepted_case) }
    it { is_expected.not_to   permit(manager,           pending_dacu_clearance_case) }
    it { is_expected.not_to   permit(responder,         pending_dacu_clearance_case) }
  end

  permissions :can_accept_or_reject_responder_assignment? do
    it { is_expected.not_to permit(manager,           assigned_case) }
    it { is_expected.to     permit(responder,         assigned_case) }
    it { is_expected.not_to permit(another_responder, assigned_case) }
    it { is_expected.not_to permit(approver,          assigned_case) }
  end

  permissions :can_download_stats? do
    it { is_expected.to     permit(manager,               assigned_case) }
    it { is_expected.to     permit(responder,             assigned_case) }
    it { is_expected.to     permit(another_responder,     assigned_case) }
    it { is_expected.not_to permit(disclosure_specialist, assigned_case) }
  end

  permissions :can_add_attachment? do
    context "when in drafting state" do
      it { is_expected.not_to permit(manager,           accepted_case) }
      it { is_expected.to     permit(responder,         accepted_case) }
      it { is_expected.to     permit(coworker,          accepted_case) }
      it { is_expected.not_to permit(another_responder, accepted_case) }
    end

    context "when in awaiting_dispatch state" do
      context "and flagged case" do
        it { is_expected.not_to permit(manager,           flagged_accepted_case) }
        it { is_expected.not_to permit(responder,         flagged_accepted_case) }
        it { is_expected.not_to permit(coworker,          flagged_accepted_case) }
        it { is_expected.not_to permit(another_responder, flagged_accepted_case) }
      end

      context "and unflagged_case" do
        it { is_expected.not_to permit(manager,           case_with_response) }
        it { is_expected.to     permit(responder,         case_with_response) }
        it { is_expected.to     permit(coworker,          case_with_response) }
        it { is_expected.not_to permit(another_responder, case_with_response) }
      end
    end
  end

  permissions :can_add_attachment_to_flagged_and_unflagged_cases? do
    context "when in awaiting dispatch_state" do
      context "and flagged case" do
        it { is_expected.not_to permit(manager,           flagged_accepted_case) }
        it { is_expected.to     permit(responder,         flagged_accepted_case) }
        it { is_expected.to     permit(coworker,          flagged_accepted_case) }
        it { is_expected.not_to permit(another_responder, flagged_accepted_case) }
        it { is_expected.not_to permit(approver,          flagged_accepted_case) }
      end

      context "and unflagged case" do
        it { is_expected.not_to permit(manager,           accepted_case) }
        it { is_expected.to     permit(responder,         accepted_case) }
        it { is_expected.to     permit(coworker,          accepted_case) }
        it { is_expected.not_to permit(another_responder, accepted_case) }
        it { is_expected.not_to permit(approver,          accepted_case) }
      end

      context "and pending clearance case" do
        it { is_expected.not_to permit(manager,           pending_dacu_clearance_case) }
        it { is_expected.not_to permit(responder,         pending_dacu_clearance_case) }
        it { is_expected.not_to permit(coworker,          pending_dacu_clearance_case) }
        it { is_expected.not_to permit(another_responder, pending_dacu_clearance_case) }
        it { is_expected.to     permit(approver,          pending_dacu_clearance_case) }
      end

      context "and case being re-drafted after approval" do
        it { is_expected.to     permit(responder,         redrafting_case) }
        it { is_expected.to     permit(coworker,          redrafting_case) }
        it { is_expected.not_to permit(manager,           redrafting_case) }
        it { is_expected.not_to permit(another_responder, redrafting_case) }
      end
    end
  end

  permissions :can_add_case? do
    it { is_expected.not_to permit(responder, new_case) }
    it { is_expected.to     permit(manager,   new_case) }
  end

  permissions :destroy_case? do
    it { is_expected.not_to permit(responder,              new_case) }
    it { is_expected.not_to permit(disclosure_specialist,  assigned_trigger_case) }
    it { is_expected.to     permit(manager,                new_case) }
  end

  permissions :can_assign_case? do
    it { is_expected.not_to permit(responder, new_case) }
    it { is_expected.to     permit(manager,   new_case) }
    it { is_expected.not_to permit(manager,   assigned_case) }
    it { is_expected.not_to permit(responder, assigned_case) }
  end

  permissions :can_close_case? do
    it { is_expected.not_to permit(responder, responded_case) }
    it { is_expected.to     permit(manager,   responded_case) }
  end

  permissions :can_flag_for_clearance? do
    it { is_expected.not_to permit(responder, assigned_case) }
    it { is_expected.to     permit(manager,   assigned_case) }
    it { is_expected.to     permit(approver,  assigned_case) }
  end

  permissions :can_remove_attachment? do
    context "when case is still being drafted" do
      it { is_expected.to     permit(responder,         case_with_response) }
      it { is_expected.not_to permit(another_responder, case_with_response) }
      it { is_expected.not_to permit(manager,           case_with_response) }
    end

    context "when case has been marked as responded" do
      it { is_expected.not_to permit(another_responder, responded_case) }
      it { is_expected.not_to permit(manager,           responded_case) }
    end
  end

  permissions :can_respond? do
    it { is_expected.not_to permit(manager,           case_with_response) }
    it { is_expected.to     permit(responder,         case_with_response) }
    it { is_expected.to     permit(coworker,          case_with_response) }
    it { is_expected.not_to permit(another_responder, case_with_response) }
    it { is_expected.not_to permit(responder,         accepted_case) }
    it { is_expected.not_to permit(coworker,          accepted_case) }
  end

  context "when unflag for clearance event" do
    permissions :unflag_for_clearance? do
      it { is_expected.not_to permit(manager,               unassigned_flagged_case) }
      it { is_expected.to     permit(disclosure_specialist, unassigned_flagged_case) }
      it { is_expected.not_to permit(press_officer,         unassigned_flagged_case) }
      it { is_expected.not_to permit(private_officer,       unassigned_flagged_case) }
      it { is_expected.not_to permit(responder,             unassigned_flagged_case) }
      it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
      it { is_expected.not_to permit(disclosure_specialist, press_flagged_case) }
    end
  end

  permissions :assignments_reassign_user? do
    context "when unflagged case" do
      it { is_expected.to     permit(responder, accepted_case) }
      it { is_expected.not_to permit(approver, accepted_case) }
    end

    context "when flagged by not yet taken by approver" do
      it { is_expected.to  permit(responder, flagged_accepted_case) }

      it "does not permit" do
        expect(flagged_accepted_case.requires_clearance?).to be true
        expect(flagged_accepted_case.approvers).to be_empty
        expect(described_class).not_to permit(approver, flagged_accepted_case)
      end
    end

    context "when flagged case taken on" do
      it "does not permit" do
        expect(described_class).to permit(responder, pending_dacu_clearance_case)
      end

      it "does permit" do
        expect(pending_dacu_clearance_case.requires_clearance?).to be true
        expect(pending_dacu_clearance_case.approvers.first)
          .to be_instance_of(User)
        expect(described_class).to permit(pending_dacu_clearance_case.approvers.first, pending_dacu_clearance_case)
      end
    end

    context "when case is being finalised" do
      it { is_expected.not_to permit(responder, responded_case) }
      it { is_expected.not_to permit(coworker, responded_case) }
      it { is_expected.not_to permit(approver, responded_case) }
      it { is_expected.not_to permit(approver, awaiting_dispatch_flagged_case) }
    end

    context "when case is closed" do
      it { is_expected.not_to permit(responder,         closed_case) }
      it { is_expected.not_to permit(coworker,          closed_case) }
      it { is_expected.not_to permit(another_responder, closed_case) }
      it { is_expected.not_to permit(approver,          closed_case) }
      it { is_expected.not_to permit(co_approver,       closed_case) }
    end

    context "when managers should not need to assign to another team member" do
      it { is_expected.not_to permit(manager, assigned_case) }
      it { is_expected.not_to permit(manager, assigned_trigger_case) }
      it { is_expected.not_to permit(manager, closed_case) }
    end
  end

  permissions :can_approve_or_escalate_case? do
    it { is_expected.not_to permit(disclosure_specialist, case_with_response) }
    it { is_expected.to     permit(disclosure_specialist, pending_dacu_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist, pending_press_clearance_case) }
    it { is_expected.not_to permit(press_officer,         case_with_response) }
    it { is_expected.not_to permit(press_officer,         pending_dacu_clearance_case) }
    it { is_expected.to     permit(press_officer,         pending_press_clearance_case) }
  end

  permissions :can_add_message_to_case? do
    # let(:flagged_case_responder)  { pending_dacu_clearance_case.responder }
    # let(:other_responder) { create :responder }

    context "when closed case" do
      it { is_expected.to     permit(manager,     closed_case) }
      it { is_expected.to     permit(approver,    closed_case) }
      it { is_expected.to     permit(responder,   closed_case) }
    end

    context "when open case" do
      it { is_expected.to     permit(manager,                   pending_dacu_clearance_case) }
      it { is_expected.to     permit(approver,                  pending_dacu_clearance_case) }
      it { is_expected.to     permit(responder, pending_dacu_clearance_case) }
      it { is_expected.not_to permit(another_responder, pending_dacu_clearance_case) }
    end
  end

  permissions :approve? do
    let(:flagged_case_responder) { pending_dacu_clearance_case.responder }

    it { is_expected.not_to permit(manager,   pending_dacu_clearance_case) }
    it { is_expected.to     permit(approver,  pending_dacu_clearance_case) }
    it { is_expected.not_to permit(responder, pending_dacu_clearance_case) }
  end

  permissions :upload_responses? do
    it { is_expected.not_to permit(manager,                accepted_case) }
    it { is_expected.to     permit(responder,              accepted_case) }
    it { is_expected.to     permit(responder,              flagged_accepted_case) }
    it { is_expected.not_to permit(disclosure_specialist,  accepted_case) }
    it { is_expected.not_to permit(press_officer,          accepted_case) }
    it { is_expected.not_to permit(manager,                flagged_accepted_case) }
    it { is_expected.not_to permit(disclosure_specialist,  flagged_accepted_case) }
    it { is_expected.not_to permit(press_officer,          flagged_accepted_case) }
    it { is_expected.not_to permit(manager,                pending_dacu_clearance_case) }
    it { is_expected.not_to permit(responder,              pending_dacu_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist,  pending_dacu_clearance_case) }
    it { is_expected.not_to permit(press_officer,          pending_dacu_clearance_case) }
    it { is_expected.not_to permit(manager,                pending_press_clearance_case) }
    it { is_expected.not_to permit(responder,              pending_press_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist,  pending_press_clearance_case) }
    it { is_expected.not_to permit(press_officer,          pending_press_clearance_case) }
  end

  permissions :upload_response_and_approve? do
    it { is_expected.not_to permit(manager,                accepted_case) }
    it { is_expected.not_to permit(responder,              accepted_case) }
    it { is_expected.not_to permit(disclosure_specialist,  accepted_case) }
    it { is_expected.not_to permit(press_officer,          accepted_case) }
    it { is_expected.not_to permit(manager,                flagged_accepted_case) }
    it { is_expected.not_to permit(responder,              flagged_accepted_case) }
    it { is_expected.not_to permit(disclosure_specialist,  flagged_accepted_case) }
    it { is_expected.not_to permit(press_officer,          flagged_accepted_case) }
    it { is_expected.not_to permit(manager,                pending_dacu_clearance_case) }
    it { is_expected.not_to permit(responder,              pending_dacu_clearance_case) }
    it { is_expected.to     permit(disclosure_specialist,  pending_dacu_clearance_case) }
    it { is_expected.not_to permit(press_officer,          pending_dacu_clearance_case) }
    it { is_expected.not_to permit(manager,                pending_press_clearance_case) }
    it { is_expected.not_to permit(responder,              pending_press_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist,  pending_press_clearance_case) }
    it { is_expected.not_to permit(press_officer,          pending_press_clearance_case) }
  end

  permissions :upload_response_and_return_for_redraft? do
    it { is_expected.not_to permit(manager,                accepted_case) }
    it { is_expected.not_to permit(responder,              accepted_case) }
    it { is_expected.not_to permit(disclosure_specialist,  accepted_case) }
    it { is_expected.not_to permit(press_officer,          accepted_case) }
    it { is_expected.not_to permit(manager,                flagged_accepted_case) }
    it { is_expected.not_to permit(responder,              flagged_accepted_case) }
    it { is_expected.not_to permit(disclosure_specialist,  flagged_accepted_case) }
    it { is_expected.not_to permit(press_officer,          flagged_accepted_case) }
    it { is_expected.not_to permit(manager,                pending_dacu_clearance_case) }
    it { is_expected.not_to permit(responder,              pending_dacu_clearance_case) }
    it { is_expected.to     permit(disclosure_specialist,  pending_dacu_clearance_case) }
    it { is_expected.not_to permit(press_officer,          pending_dacu_clearance_case) }
    it { is_expected.not_to permit(manager,                pending_press_clearance_case) }
    it { is_expected.not_to permit(responder,              pending_press_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist,  pending_press_clearance_case) }
    it { is_expected.not_to permit(press_officer,          pending_press_clearance_case) }
  end

  permissions :extend_for_pit? do
    it { is_expected.not_to permit(responder,             accepted_case) }
    it { is_expected.to     permit(manager,               accepted_case) }
    it { is_expected.to     permit(manager,               drafting_trigger_case) }
    it { is_expected.not_to permit(manager,               unassigned_case) }
    it { is_expected.not_to permit(manager,               closed_case) }
    it { is_expected.not_to permit(approver,              drafting_trigger_case) }
    it { is_expected.not_to permit(press_officer,         accepted_case) }
    it { is_expected.not_to permit(private_officer,       accepted_case) }
  end

  permissions :request_further_clearance? do
    it { is_expected.not_to permit(responder,             accepted_case) }
    it { is_expected.to     permit(manager,               accepted_case) }
    it { is_expected.to     permit(manager,               case_with_response) }
    it { is_expected.to     permit(manager,               unassigned_case) }
    it { is_expected.not_to permit(manager,               closed_case) }
    it { is_expected.not_to permit(disclosure_specialist, accepted_case) }
    it { is_expected.not_to permit(press_officer,         accepted_case) }
    it { is_expected.not_to permit(private_officer,       accepted_case) }
  end

  permissions :new_case_link? do
    it { is_expected.not_to permit(another_responder,     assigned_case) }

    it { is_expected.not_to permit(responder,             unassigned_case) }
    it { is_expected.not_to permit(responder,             assigned_case) }
    it { is_expected.not_to permit(responder,             closed_case) }
    it { is_expected.not_to permit(responder,             responded_case) }
    it { is_expected.to     permit(responder,             case_with_response) }
    it { is_expected.not_to permit(responder,             responded_case) }
    it { is_expected.to     permit(manager,               accepted_case) }
    it { is_expected.to     permit(manager,               case_with_response) }
    it { is_expected.to     permit(manager,               unassigned_case) }
    it { is_expected.to     permit(manager,               closed_case) }
    it { is_expected.not_to permit(disclosure_specialist, accepted_case) }
    it { is_expected.to     permit(disclosure_specialist, pending_dacu_clearance_case) }
    it { is_expected.to     permit(disclosure_specialist, unassigned_flagged_case) }
    it { is_expected.to     permit(disclosure_specialist, unassigned_trigger_case) }
    it { is_expected.not_to permit(press_officer,         accepted_case) }
    it { is_expected.to     permit(press_officer,         pending_press_clearance_case) }
    it { is_expected.not_to permit(press_officer,         accepted_case) }
    it { is_expected.not_to permit(private_officer,       accepted_case) }
    it { is_expected.to     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :show? do
    it "raises an exception" do
      expect {
        Pundit.policy(manager, Case::Base).show?
      }.to raise_error(Pundit::NotDefinedError)
    end
  end

  permissions :remove_clearance? do
    it { is_expected.not_to permit(manager,               unassigned_case) }
    it { is_expected.not_to permit(manager,               unassigned_flagged_case) }
    it { is_expected.not_to permit(manager,               assigned_case) }
    it { is_expected.not_to permit(manager,               assigned_flagged_case) }
    it { is_expected.not_to permit(manager,               case_with_response) }
    it { is_expected.not_to permit(manager,               case_with_response_flagged) }
    it { is_expected.not_to permit(manager,               responded_case) }
    it { is_expected.not_to permit(manager,               closed_case) }

    it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
    it { is_expected.to     permit(disclosure_specialist, unassigned_flagged_case) }
    it { is_expected.not_to permit(disclosure_specialist, assigned_case) }
    it { is_expected.to     permit(disclosure_specialist, assigned_flagged_case) }
    it { is_expected.not_to permit(disclosure_specialist, case_with_response) }
    it { is_expected.not_to permit(disclosure_specialist, case_with_response_flagged) }
    it { is_expected.not_to permit(disclosure_specialist, responded_case) }
    it { is_expected.not_to permit(disclosure_specialist, closed_case) }

    it { is_expected.not_to permit(responder,             unassigned_case) }
    it { is_expected.not_to permit(responder,             unassigned_flagged_case) }
    it { is_expected.not_to permit(responder,             assigned_case) }
    it { is_expected.not_to permit(responder,             assigned_flagged_case) }
    it { is_expected.not_to permit(responder,             case_with_response) }
    it { is_expected.not_to permit(responder,             case_with_response_flagged) }
    it { is_expected.not_to permit(responder,             responded_case) }
    it { is_expected.not_to permit(responder,             closed_case) }
  end

  permissions :update_closure? do
    it "returns true if the event can be triggered by the state machine" do
      allow(closed_case.state_machine).to receive(:can_trigger_event?).and_return(true)
      expect(described_class).to permit(manager, closed_case)
      expect(closed_case.state_machine).to have_received(:can_trigger_event?).with(
        event_name: :update_closure,
        metadata: { acting_user: manager },
      )
    end

    it "returns false if the event cannot be triggered by the state machine" do
      allow(closed_case.state_machine).to receive(:can_trigger_event?).and_return(false)
      expect(described_class).not_to permit(manager, closed_case)
      expect(closed_case.state_machine).to have_received(:can_trigger_event?).with(
        event_name: :update_closure,
        metadata: { acting_user: manager },
      )
    end
  end

  permissions :can_record_data_request? do
    it { is_expected.not_to permit(manager, unassigned_case) }
  end

  permissions :can_manage_offender_sar? do
    it { is_expected.not_to permit(manager,               unassigned_case) }
    it { is_expected.not_to permit(manager,               unassigned_flagged_case) }
    it { is_expected.not_to permit(manager,               assigned_case) }
    it { is_expected.not_to permit(manager,               assigned_flagged_case) }
    it { is_expected.not_to permit(manager,               case_with_response) }
    it { is_expected.not_to permit(manager,               case_with_response_flagged) }
    it { is_expected.not_to permit(manager,               responded_case) }
    it { is_expected.not_to permit(manager,               closed_case) }
    it { is_expected.not_to permit(manager,               offender_sar_case) }
    it { is_expected.not_to permit(manager,               offender_sar_complaint) }

    it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
    it { is_expected.not_to permit(disclosure_specialist, unassigned_flagged_case) }
    it { is_expected.not_to permit(disclosure_specialist, assigned_case) }
    it { is_expected.not_to permit(disclosure_specialist, assigned_flagged_case) }
    it { is_expected.not_to permit(disclosure_specialist, case_with_response) }
    it { is_expected.not_to permit(disclosure_specialist, case_with_response_flagged) }
    it { is_expected.not_to permit(disclosure_specialist, responded_case) }
    it { is_expected.not_to permit(disclosure_specialist, closed_case) }
    it { is_expected.not_to permit(disclosure_specialist, offender_sar_case) }
    it { is_expected.not_to permit(disclosure_specialist, offender_sar_complaint) }

    it { is_expected.not_to permit(responder,             unassigned_case) }
    it { is_expected.not_to permit(responder,             unassigned_flagged_case) }
    it { is_expected.not_to permit(responder,             assigned_case) }
    it { is_expected.not_to permit(responder,             assigned_flagged_case) }
    it { is_expected.not_to permit(responder,             case_with_response) }
    it { is_expected.not_to permit(responder,             case_with_response_flagged) }
    it { is_expected.not_to permit(responder,             responded_case) }
    it { is_expected.not_to permit(responder,             closed_case) }
    it { is_expected.not_to permit(responder,             offender_sar_case) }
    it { is_expected.not_to permit(responder,             offender_sar_complaint) }

    it { is_expected.to permit(branston_user,             offender_sar_case) }
    it { is_expected.to permit(branston_user,             offender_sar_complaint) }
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll, RSpec/RepeatedExample
