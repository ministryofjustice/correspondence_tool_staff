require 'rails_helper'

describe 'state machine' do

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new
  end

  after(:all) { DbHousekeeping.clean }


  describe 'setup' do
    describe '@setup.full_pdacu_foi_accepted' do
      it 'accepted by all three approving teams ' do
        kase = @setup.full_pdacu_foi_accepted
        expect(kase.current_state).to eq 'pending_dacu_clearance'
        expect(kase.workflow).to eq 'full_approval'
        expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq 'accepted'
        expect(kase.approver_assignments.for_team(@setup.press_office_team).first.state).to eq 'accepted'
        expect(kase.approver_assignments.for_team(@setup.private_office_team).first.state).to eq 'accepted'
      end
    end

    describe '@setup.full_dacu_foi_unaccpted' do
      it 'accepted by press and private but not disclosure' do
        kase = @setup.full_pdacu_foi_unaccepted
        expect(kase.current_state).to eq 'pending_dacu_clearance'
        expect(kase.workflow).to eq 'full_approval'
        expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq 'pending'
        expect(kase.approver_assignments.for_team(@setup.press_office_team).first.state).to eq 'accepted'
        expect(kase.approver_assignments.for_team(@setup.private_office_team).first.state).to eq 'accepted'
      end
    end
  end

  describe :accept_approver_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_specialist, :trig_unassigned_foi],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :trig_pdacu_foi],
        [:disclosure_specialist, :full_unassigned_foi],
        [:disclosure_specialist, :full_awresp_foi],
        [:disclosure_specialist, :full_draft_foi],
        [:disclosure_specialist, :full_awdis_foi],         # standard state machine wrongly allowing this - remove when converting to config state machine
        [:disclosure_specialist, :full_responded_foi],     # standard state machine wrongly allowing this - remove when converting to config state machine
        [:disclosure_specialist, :full_pdacu_foi_unaccepted],

        [:disclosure_specialist_coworker, :trig_unassigned_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :trig_pdacu_foi],
        [:disclosure_specialist_coworker, :full_unassigned_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi],
        [:disclosure_specialist_coworker, :full_draft_foi],
        [:disclosure_specialist_coworker, :full_awdis_foi],         # standard state machine wrongly allowing this - remove when converting to config state machine
        [:disclosure_specialist_coworker, :full_responded_foi],     # standard state machine wrongly allowing this - remove when converting to config state machine
        [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],

        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_awdis_foi],        # standard state machine wrongly allowing this - remove when converting to config state machine
        [:private_officer, :full_responded_foi],    # standard state machine wrongly allowing this - remove when converting to config state machine

        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_awdis_foi],        # standard state machine wrongly allowing this - remove when converting to config state machine
        [:press_officer, :full_responded_foi],    # standard state machine wrongly allowing this - remove when converting to config state machine


      )
    }
  end

  describe :accept_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awresp_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :full_awresp_foi],
        [:responder, :trig_awresp_foi_accepted],
        [:responder, :full_awresp_foi_accepted],
        [:another_responder_in_same_team, :std_awresp_foi],
        [:another_responder_in_same_team, :trig_awresp_foi],
        [:another_responder_in_same_team, :full_awresp_foi],
        [:another_responder_in_same_team, :trig_awresp_foi_accepted],
        [:another_responder_in_same_team, :full_awresp_foi_accepted]
      )
    }
  end

  describe :add_message_to_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :std_awdis_foi],
        [:disclosure_bmt, :std_responded_foi],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :trig_pdacu_foi],
        [:disclosure_bmt, :trig_awdis_foi],
        [:disclosure_bmt, :trig_responded_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_draft_foi],
        [:disclosure_bmt, :full_ppress_foi],
        [:disclosure_bmt, :full_pprivate_foi],
        [:disclosure_bmt, :full_awdis_foi],
        [:disclosure_bmt, :full_responded_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :trig_pdacu_foi_accepted],
        [:disclosure_bmt, :full_awresp_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_unaccepted],
        [:disclosure_bmt, :full_ppress_foi_accepted],
        [:disclosure_bmt, :full_pprivate_foi_accepted],
        
        [:disclosure_specialist, :trig_unassigned_foi],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :trig_pdacu_foi],
        [:disclosure_specialist, :trig_awdis_foi],
        [:disclosure_specialist, :trig_responded_foi],
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :full_awresp_foi_accepted],
        [:disclosure_specialist, :full_unassigned_foi],
        [:disclosure_specialist, :full_awresp_foi],
        [:disclosure_specialist, :full_draft_foi],
        [:disclosure_specialist, :full_ppress_foi],
        [:disclosure_specialist, :full_pprivate_foi],
        [:disclosure_specialist, :full_awdis_foi],
        [:disclosure_specialist, :full_responded_foi],
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        [:disclosure_specialist, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist, :full_ppress_foi_accepted],
        [:disclosure_specialist, :full_pprivate_foi_accepted],

        [:disclosure_specialist_coworker, :trig_unassigned_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :trig_pdacu_foi],
        [:disclosure_specialist_coworker, :trig_awdis_foi],
        [:disclosure_specialist_coworker, :trig_responded_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
        [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :full_unassigned_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi],
        [:disclosure_specialist_coworker, :full_draft_foi],
        [:disclosure_specialist_coworker, :full_ppress_foi],
        [:disclosure_specialist_coworker, :full_pprivate_foi],
        [:disclosure_specialist_coworker, :full_awdis_foi],
        [:disclosure_specialist_coworker, :full_responded_foi],
        [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist_coworker, :full_ppress_foi_accepted],
        [:disclosure_specialist_coworker, :full_pprivate_foi_accepted],

        [:another_disclosure_specialist, :trig_unassigned_foi],
        [:another_disclosure_specialist, :trig_awresp_foi],
        [:another_disclosure_specialist, :trig_draft_foi],
        [:another_disclosure_specialist, :trig_pdacu_foi],

        # [:another_disclosure_specialist, :trig_awdis_foi],           # old state machine - they should be allowed
        # [:another_disclosure_specialist, :trig_responded_foi],        # old state machine - they should be allowed
        [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
        [:another_disclosure_specialist, :trig_awresp_foi_accepted],
        [:another_disclosure_specialist, :trig_draft_foi_accepted],
        [:another_disclosure_specialist, :trig_pdacu_foi_accepted],

        [:responder, :std_awresp_foi],
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_draft_foi],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_awdis_foi],
        # [:responder, :trig_responded_foi],        # old state machine - they should be allowed
        [:responder, :trig_awresp_foi_accepted],
        [:responder, :trig_draft_foi_accepted],
        [:responder, :trig_pdacu_foi_accepted],
        [:responder, :full_awresp_foi_accepted],
        [:responder, :full_awresp_foi],
        [:responder, :full_draft_foi],
        [:responder, :full_ppress_foi],
        [:responder, :full_pprivate_foi],
        [:responder, :full_awdis_foi],
        # [:responder, :full_responded_foi],          # old state machine - they should be allowed
        [:responder, :full_pdacu_foi_accepted],
        [:responder, :full_pdacu_foi_unaccepted],
        [:responder, :full_ppress_foi_accepted],
        [:responder, :full_pprivate_foi_accepted],


        [:another_responder_in_same_team, :std_awresp_foi],
        [:another_responder_in_same_team, :std_draft_foi],
        [:another_responder_in_same_team, :std_awdis_foi],
        [:another_responder_in_same_team, :std_responded_foi],
        [:another_responder_in_same_team, :trig_awresp_foi],
        [:another_responder_in_same_team, :trig_awresp_foi_accepted],
        [:another_responder_in_same_team, :trig_draft_foi],
        [:another_responder_in_same_team, :trig_draft_foi_accepted],
        [:another_responder_in_same_team, :trig_pdacu_foi],
        [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
        [:another_responder_in_same_team, :trig_awdis_foi],
        # [:another_responder_in_same_team, :trig_responded_foi],       # old state machine - they should be allowed
        [:another_responder_in_same_team, :full_awresp_foi],
        [:another_responder_in_same_team, :full_awresp_foi_accepted],
        [:another_responder_in_same_team, :full_draft_foi],
        [:another_responder_in_same_team, :full_ppress_foi],
        [:another_responder_in_same_team, :full_pprivate_foi],
        [:another_responder_in_same_team, :full_awdis_foi],
        # [:another_responder_in_same_team, :full_responded_foi],        # old state machine - they should be allowed
        [:another_responder_in_same_team, :full_pdacu_foi_accepted],
        [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
        [:another_responder_in_same_team, :full_ppress_foi_accepted],
        [:another_responder_in_same_team, :full_pprivate_foi_accepted],


        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_pdacu_foi],
        [:press_officer, :trig_unassigned_foi_accepted],
        [:press_officer, :trig_awresp_foi_accepted],
        [:press_officer, :trig_draft_foi_accepted],
        [:press_officer, :trig_pdacu_foi_accepted],
        [:press_officer, :full_awresp_foi_accepted],
        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_pprivate_foi],
        [:press_officer, :full_awdis_foi],
        [:press_officer, :full_responded_foi],
        [:press_officer, :full_pdacu_foi_accepted],
        [:press_officer, :full_pdacu_foi_unaccepted],
        [:press_officer, :full_ppress_foi_accepted],
        [:press_officer, :full_pprivate_foi_accepted],



        [:private_officer, :trig_unassigned_foi],
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_pdacu_foi],
        [:private_officer, :trig_unassigned_foi_accepted],
        [:private_officer, :trig_awresp_foi_accepted],
        [:private_officer, :trig_draft_foi_accepted],
        [:private_officer, :trig_pdacu_foi_accepted],
        [:private_officer, :full_awresp_foi_accepted],
        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_ppress_foi],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_awdis_foi],
        [:private_officer, :full_responded_foi],
        [:private_officer, :full_pdacu_foi_accepted],
        [:private_officer, :full_pdacu_foi_unaccepted],
        [:private_officer, :full_ppress_foi_accepted],
        [:private_officer, :full_pprivate_foi_accepted]

      )
    }
  end

  describe :add_response_to_flagged_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :trig_draft_foi],
        [:responder, :trig_draft_foi_accepted],
        [:responder, :full_draft_foi],
        [:another_responder_in_same_team, :trig_draft_foi],
        [:another_responder_in_same_team, :full_draft_foi],
        [:another_responder_in_same_team, :trig_draft_foi_accepted]
        )}
  end

  describe :add_responses do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:another_responder_in_same_team, :std_draft_foi],
        [:another_responder_in_same_team, :std_awdis_foi],
        )}
  end

  describe :approve do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        # [:press_officer, :full_ppress_foi_accepted],          # old state machine - they should be allowed
        # [:private_officer, :full_pprivate_foi_accepted],      # old state machine - they should be allowed
        )}
  end

  describe :approve_and_bypass do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        )}
  end

  describe :assign_responder do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        )}
  end

  describe :assign_to_new_team do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_awresp_foi_accepted],
        [:disclosure_bmt, :full_draft_foi],
        )}
  end

  describe :close do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_responded_foi],
        [:disclosure_bmt, :trig_responded_foi],
        [:disclosure_bmt, :full_responded_foi],
        )}
  end

  describe :destroy_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :std_awdis_foi],
        [:disclosure_bmt, :std_responded_foi],
        [:disclosure_bmt, :std_closed_foi],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :trig_pdacu_foi],
        [:disclosure_bmt, :trig_pdacu_foi_accepted],
        [:disclosure_bmt, :trig_awdis_foi],
        [:disclosure_bmt, :trig_responded_foi],
        [:disclosure_bmt, :trig_closed_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_awresp_foi_accepted],
        [:disclosure_bmt, :full_draft_foi],
        [:disclosure_bmt, :full_pdacu_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_unaccepted],
        [:disclosure_bmt, :full_ppress_foi],
        [:disclosure_bmt, :full_ppress_foi_accepted],
        [:disclosure_bmt, :full_pprivate_foi],
        [:disclosure_bmt, :full_pprivate_foi_accepted],
        [:disclosure_bmt, :full_awdis_foi],
        [:disclosure_bmt, :full_responded_foi],
        [:disclosure_bmt, :full_closed_foi]
        )}
  end

  describe :edit_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :std_awdis_foi],
        [:disclosure_bmt, :std_responded_foi],
        [:disclosure_bmt, :std_closed_foi],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :trig_pdacu_foi],
        [:disclosure_bmt, :trig_pdacu_foi_accepted],
        [:disclosure_bmt, :trig_awdis_foi],
        [:disclosure_bmt, :trig_responded_foi],
        [:disclosure_bmt, :trig_closed_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_awresp_foi_accepted],
        [:disclosure_bmt, :full_draft_foi],
        [:disclosure_bmt, :full_pdacu_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_unaccepted],
        [:disclosure_bmt, :full_ppress_foi],
        [:disclosure_bmt, :full_ppress_foi_accepted],
        [:disclosure_bmt, :full_pprivate_foi],
        [:disclosure_bmt, :full_pprivate_foi_accepted],
        [:disclosure_bmt, :full_awdis_foi],
        [:disclosure_bmt, :full_responded_foi],
        [:disclosure_bmt, :full_closed_foi]
        )}
  end

  describe :extend_for_pit do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :trig_awdis_foi],
        [:disclosure_specialist, :trig_responded_foi],
        # [:disclosure_specialist, :full_draft_foi_accepted], # should we add this case in for consistency?
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        [:disclosure_specialist, :full_ppress_foi_accepted],
        [:disclosure_specialist, :full_ppress_foi],
        [:disclosure_specialist, :full_pprivate_foi],
        [:disclosure_specialist, :full_pprivate_foi_accepted],
        [:disclosure_specialist, :full_awdis_foi],
        [:disclosure_specialist, :full_responded_foi],

        [:disclosure_specialist_coworker, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_specialist_coworker, :full_responded_foi],          # old state machine - they shouldn't be allowed


        # the following combinations are allowed by the old state machine but shouldn't be allowed
        [:disclosure_bmt, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:disclosure_bmt, :full_responded_foi],          # old state machine - they shouldn't be allowed

        [:another_disclosure_specialist, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_disclosure_specialist, :full_responded_foi],          # old state machine - they shouldn't be allowed

        [:responder, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:responder, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:responder, :full_ppress_foi],
        [:responder, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:responder, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:responder, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:responder, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:responder, :full_responded_foi],          # old state machine - they shouldn't be allowed

        [:another_responder_in_same_team, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_responded_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_same_team, :full_responded_foi],          # old state machine - they shouldn't be allowed

        [:another_responder_in_diff_team, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:another_responder_in_diff_team, :full_responded_foi],          # old state machine - they shouldn't be allowed

        [:press_officer, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:press_officer, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:press_officer, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:press_officer, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:press_officer, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:press_officer, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:press_officer, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:press_officer, :full_responded_foi],          # old state machine - they shouldn't be allowed

        [:private_officer, :trig_awdis_foi],          # old state machine - they shouldn't be allowed
        [:private_officer, :trig_responded_foi],          # old state machine - they shouldn't be allowed
        [:private_officer, :full_ppress_foi],          # old state machine - they shouldn't be allowed
        [:private_officer, :full_ppress_foi_accepted],          # old state machine - they shouldn't be allowed
        [:private_officer, :full_pprivate_foi],          # old state machine - they shouldn't be allowed
        [:private_officer, :full_pprivate_foi_accepted],          # old state machine - they shouldn't be allowed
        [:private_officer, :full_awdis_foi],          # old state machine - they shouldn't be allowed
        [:private_officer, :full_responded_foi],          # old state machine - they shouldn't be allowed

        )}
  end

  describe :flag_for_clearance do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_draft_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :full_awresp_foi_accepted],

        [:disclosure_bmt, :std_awdis_foi],               # old state machine allows it but shouldn't
        [:disclosure_bmt, :trig_awdis_foi],              # old state machine allows it but shouldn't
        [:disclosure_bmt, :full_awdis_foi],               # old state machine allows it but shouldn't

        [:disclosure_specialist, :std_unassigned_foi],
        [:disclosure_specialist, :std_awresp_foi],
        [:disclosure_specialist, :std_draft_foi],
        [:disclosure_specialist, :trig_unassigned_foi],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :full_unassigned_foi],
        [:disclosure_specialist, :full_awresp_foi],
        [:disclosure_specialist, :full_draft_foi],
        [:disclosure_specialist, :trig_awdis_foi],             # old state machine allows it but shouldn't
        [:disclosure_specialist, :full_awdis_foi],             # old state machine allows it but shouldn't
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :full_awresp_foi_accepted],

        [:disclosure_specialist_coworker, :std_unassigned_foi],
        [:disclosure_specialist_coworker, :std_awresp_foi],
        [:disclosure_specialist_coworker, :std_draft_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :full_unassigned_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi],
        [:disclosure_specialist_coworker, :full_draft_foi],
        [:disclosure_specialist_coworker, :trig_awdis_foi],             # old state machine allows it but shouldn't
        [:disclosure_specialist_coworker, :full_awdis_foi],             # old state machine allows it but shouldn't
        [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
        [:disclosure_specialist_coworker, :full_awresp_foi_accepted],

        [:another_disclosure_specialist, :std_unassigned_foi],
        [:another_disclosure_specialist, :std_awresp_foi],
        [:another_disclosure_specialist, :std_draft_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi],
        [:another_disclosure_specialist, :trig_awresp_foi],
        [:another_disclosure_specialist, :trig_draft_foi],
        [:another_disclosure_specialist, :full_unassigned_foi],
        [:another_disclosure_specialist, :full_awresp_foi],
        [:another_disclosure_specialist, :full_draft_foi],
        [:another_disclosure_specialist, :trig_awdis_foi],     # old state machine allows it but shouldn't
        [:another_disclosure_specialist, :full_awdis_foi],      # old state machine allows it but shouldn't
        [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
        [:another_disclosure_specialist, :trig_awresp_foi_accepted],
        [:another_disclosure_specialist, :trig_draft_foi_accepted],
        [:another_disclosure_specialist, :full_awresp_foi_accepted],

        [:press_officer, :std_unassigned_foi],
        [:press_officer, :std_awresp_foi],
        [:press_officer, :std_draft_foi],
        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_draft_foi],
        [:press_officer, :trig_awdis_foi],     # old state machine allows it but shouldn't
        [:press_officer, :full_awdis_foi],     # old state machine allows it but shouldn't
        [:press_officer, :trig_unassigned_foi_accepted],
        [:press_officer, :trig_awresp_foi_accepted],
        [:press_officer, :trig_draft_foi_accepted],
        [:press_officer, :full_awresp_foi_accepted],

        [:private_officer, :std_unassigned_foi],
        [:private_officer, :std_awresp_foi],
        [:private_officer, :std_draft_foi],
        [:private_officer, :trig_unassigned_foi],
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_draft_foi],
        [:private_officer, :trig_awdis_foi],     # old state machine allows it but shouldn't
        [:private_officer, :full_awdis_foi],     # old state machine allows it but shouldn't
        [:private_officer, :trig_unassigned_foi_accepted],
        [:private_officer, :trig_awresp_foi_accepted],
        [:private_officer, :trig_draft_foi_accepted],
        [:private_officer, :full_awresp_foi_accepted],
      )}
  end

  describe :link_a_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :std_awdis_foi],
        [:disclosure_bmt, :std_responded_foi],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :trig_pdacu_foi],
        [:disclosure_bmt, :trig_awdis_foi],
        [:disclosure_bmt, :trig_responded_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_draft_foi],
        [:disclosure_bmt, :full_ppress_foi],
        [:disclosure_bmt, :full_pprivate_foi],
        [:disclosure_bmt, :full_awdis_foi],
        [:disclosure_bmt, :full_responded_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :trig_pdacu_foi_accepted],
        [:disclosure_bmt, :full_awresp_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_unaccepted],
        [:disclosure_bmt, :full_ppress_foi_accepted],
        [:disclosure_bmt, :full_pprivate_foi_accepted],
        [:disclosure_bmt, :std_closed_foi],
        [:disclosure_bmt, :trig_closed_foi],
        [:disclosure_bmt, :full_closed_foi],

        [:disclosure_specialist, :std_unassigned_foi],
        [:disclosure_specialist, :std_awresp_foi],
        [:disclosure_specialist, :std_draft_foi],
        [:disclosure_specialist, :std_awdis_foi],
        [:disclosure_specialist, :std_responded_foi],
        [:disclosure_specialist, :std_closed_foi],
        [:disclosure_specialist, :trig_unassigned_foi],
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi],
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :trig_awdis_foi],
        [:disclosure_specialist, :trig_responded_foi],
        [:disclosure_specialist, :trig_closed_foi],
        [:disclosure_specialist, :full_unassigned_foi],
        [:disclosure_specialist, :full_awresp_foi],
        [:disclosure_specialist, :full_awresp_foi_accepted],
        [:disclosure_specialist, :full_draft_foi],
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        [:disclosure_specialist, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist, :full_ppress_foi],
        [:disclosure_specialist, :full_ppress_foi_accepted],
        [:disclosure_specialist, :full_pprivate_foi],
        [:disclosure_specialist, :full_pprivate_foi_accepted],
        [:disclosure_specialist, :full_awdis_foi],
        [:disclosure_specialist, :full_responded_foi],
        [:disclosure_specialist, :full_closed_foi],

        [:disclosure_specialist_coworker, :std_unassigned_foi],
        [:disclosure_specialist_coworker, :std_awresp_foi],
        [:disclosure_specialist_coworker, :std_draft_foi],
        [:disclosure_specialist_coworker, :std_awdis_foi],
        [:disclosure_specialist_coworker, :std_responded_foi],
        [:disclosure_specialist_coworker, :std_closed_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
        [:disclosure_specialist_coworker, :trig_pdacu_foi],
        [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awdis_foi],
        [:disclosure_specialist_coworker, :trig_responded_foi],
        [:disclosure_specialist_coworker, :trig_closed_foi],
        [:disclosure_specialist_coworker, :full_unassigned_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :full_draft_foi],
        [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist_coworker, :full_ppress_foi],
        [:disclosure_specialist_coworker, :full_ppress_foi_accepted],
        [:disclosure_specialist_coworker, :full_pprivate_foi],
        [:disclosure_specialist_coworker, :full_pprivate_foi_accepted],
        [:disclosure_specialist_coworker, :full_awdis_foi],
        [:disclosure_specialist_coworker, :full_responded_foi],
        [:disclosure_specialist_coworker, :full_closed_foi],

        [:another_disclosure_specialist, :std_unassigned_foi],
        [:another_disclosure_specialist, :std_awresp_foi],
        [:another_disclosure_specialist, :std_draft_foi],
        [:another_disclosure_specialist, :std_awdis_foi],
        [:another_disclosure_specialist, :std_responded_foi],
        [:another_disclosure_specialist, :std_closed_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
        [:another_disclosure_specialist, :trig_awresp_foi],
        [:another_disclosure_specialist, :trig_awresp_foi_accepted],
        [:another_disclosure_specialist, :trig_draft_foi],
        [:another_disclosure_specialist, :trig_draft_foi_accepted],
        [:another_disclosure_specialist, :trig_pdacu_foi],
        [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
        [:another_disclosure_specialist, :trig_awdis_foi],
        [:another_disclosure_specialist, :trig_responded_foi],
        [:another_disclosure_specialist, :trig_closed_foi],
        [:another_disclosure_specialist, :full_unassigned_foi],
        [:another_disclosure_specialist, :full_awresp_foi],
        [:another_disclosure_specialist, :full_awresp_foi_accepted],
        [:another_disclosure_specialist, :full_draft_foi],
        [:another_disclosure_specialist, :full_pdacu_foi_accepted],
        [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],
        [:another_disclosure_specialist, :full_ppress_foi],
        [:another_disclosure_specialist, :full_ppress_foi_accepted],
        [:another_disclosure_specialist, :full_pprivate_foi],
        [:another_disclosure_specialist, :full_pprivate_foi_accepted],
        [:another_disclosure_specialist, :full_awdis_foi],
        [:another_disclosure_specialist, :full_responded_foi],
        [:another_disclosure_specialist, :full_closed_foi],

        [:responder, :std_unassigned_foi],
        [:responder, :std_awresp_foi],
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :std_closed_foi],
        [:responder, :trig_unassigned_foi],
        [:responder, :trig_unassigned_foi_accepted],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_awresp_foi_accepted],
        [:responder, :trig_draft_foi],
        [:responder, :trig_draft_foi_accepted],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_pdacu_foi_accepted],
        [:responder, :trig_awdis_foi],
        [:responder, :trig_responded_foi],
        [:responder, :trig_closed_foi],
        [:responder, :full_unassigned_foi],
        [:responder, :full_awresp_foi],
        [:responder, :full_awresp_foi_accepted],
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi_accepted],
        [:responder, :full_pdacu_foi_unaccepted],
        [:responder, :full_ppress_foi],
        [:responder, :full_ppress_foi_accepted],
        [:responder, :full_pprivate_foi],
        [:responder, :full_pprivate_foi_accepted],
        [:responder, :full_awdis_foi],
        [:responder, :full_responded_foi],
        [:responder, :full_closed_foi],

        [:another_responder_in_same_team, :std_unassigned_foi],
        [:another_responder_in_same_team, :std_awresp_foi],
        [:another_responder_in_same_team, :std_draft_foi],
        [:another_responder_in_same_team, :std_awdis_foi],
        [:another_responder_in_same_team, :std_responded_foi],
        [:another_responder_in_same_team, :std_closed_foi],
        [:another_responder_in_same_team, :trig_unassigned_foi],
        [:another_responder_in_same_team, :trig_unassigned_foi_accepted],
        [:another_responder_in_same_team, :trig_awresp_foi],
        [:another_responder_in_same_team, :trig_awresp_foi_accepted],
        [:another_responder_in_same_team, :trig_draft_foi],
        [:another_responder_in_same_team, :trig_draft_foi_accepted],
        [:another_responder_in_same_team, :trig_pdacu_foi],
        [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
        [:another_responder_in_same_team, :trig_awdis_foi],
        [:another_responder_in_same_team, :trig_responded_foi],
        [:another_responder_in_same_team, :trig_closed_foi],
        [:another_responder_in_same_team, :full_unassigned_foi],
        [:another_responder_in_same_team, :full_awresp_foi],
        [:another_responder_in_same_team, :full_awresp_foi_accepted],
        [:another_responder_in_same_team, :full_draft_foi],
        [:another_responder_in_same_team, :full_pdacu_foi_accepted],
        [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
        [:another_responder_in_same_team, :full_ppress_foi],
        [:another_responder_in_same_team, :full_ppress_foi_accepted],
        [:another_responder_in_same_team, :full_pprivate_foi],
        [:another_responder_in_same_team, :full_pprivate_foi_accepted],
        [:another_responder_in_same_team, :full_awdis_foi],
        [:another_responder_in_same_team, :full_responded_foi],
        [:another_responder_in_same_team, :full_closed_foi],

        [:another_responder_in_diff_team, :std_unassigned_foi],
        [:another_responder_in_diff_team, :std_awresp_foi],
        [:another_responder_in_diff_team, :std_draft_foi],
        [:another_responder_in_diff_team, :std_awdis_foi],
        [:another_responder_in_diff_team, :std_responded_foi],
        [:another_responder_in_diff_team, :std_closed_foi],
        [:another_responder_in_diff_team, :trig_unassigned_foi],
        [:another_responder_in_diff_team, :trig_unassigned_foi_accepted],
        [:another_responder_in_diff_team, :trig_awresp_foi],
        [:another_responder_in_diff_team, :trig_awresp_foi_accepted],
        [:another_responder_in_diff_team, :trig_draft_foi],
        [:another_responder_in_diff_team, :trig_draft_foi_accepted],
        [:another_responder_in_diff_team, :trig_pdacu_foi],
        [:another_responder_in_diff_team, :trig_pdacu_foi_accepted],
        [:another_responder_in_diff_team, :trig_awdis_foi],
        [:another_responder_in_diff_team, :trig_responded_foi],
        [:another_responder_in_diff_team, :trig_closed_foi],
        [:another_responder_in_diff_team, :full_unassigned_foi],
        [:another_responder_in_diff_team, :full_awresp_foi],
        [:another_responder_in_diff_team, :full_awresp_foi_accepted],
        [:another_responder_in_diff_team, :full_draft_foi],
        [:another_responder_in_diff_team, :full_pdacu_foi_accepted],
        [:another_responder_in_diff_team, :full_pdacu_foi_unaccepted],
        [:another_responder_in_diff_team, :full_ppress_foi],
        [:another_responder_in_diff_team, :full_ppress_foi_accepted],
        [:another_responder_in_diff_team, :full_pprivate_foi],
        [:another_responder_in_diff_team, :full_pprivate_foi_accepted],
        [:another_responder_in_diff_team, :full_awdis_foi],
        [:another_responder_in_diff_team, :full_responded_foi],
        [:another_responder_in_diff_team, :full_closed_foi],

        [:press_officer, :std_unassigned_foi],
        [:press_officer, :std_awresp_foi],
        [:press_officer, :std_draft_foi],
        [:press_officer, :std_awdis_foi],
        [:press_officer, :std_responded_foi],
        [:press_officer, :std_closed_foi],
        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_unassigned_foi_accepted],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_awresp_foi_accepted],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_draft_foi_accepted],
        [:press_officer, :trig_pdacu_foi],
        [:press_officer, :trig_pdacu_foi_accepted],
        [:press_officer, :trig_awdis_foi],
        [:press_officer, :trig_responded_foi],
        [:press_officer, :trig_closed_foi],
        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_awresp_foi_accepted],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi_accepted],
        [:press_officer, :full_pdacu_foi_unaccepted],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_ppress_foi_accepted],
        [:press_officer, :full_pprivate_foi],
        [:press_officer, :full_pprivate_foi_accepted],
        [:press_officer, :full_awdis_foi],
        [:press_officer, :full_responded_foi],
        [:press_officer, :full_closed_foi],

        [:private_officer, :std_unassigned_foi],
        [:private_officer, :std_awresp_foi],
        [:private_officer, :std_draft_foi],
        [:private_officer, :std_awdis_foi],
        [:private_officer, :std_responded_foi],
        [:private_officer, :std_closed_foi],
        [:private_officer, :trig_unassigned_foi],
        [:private_officer, :trig_unassigned_foi_accepted],
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_awresp_foi_accepted],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_draft_foi_accepted],
        [:private_officer, :trig_pdacu_foi],
        [:private_officer, :trig_pdacu_foi_accepted],
        [:private_officer, :trig_awdis_foi],
        [:private_officer, :trig_responded_foi],
        [:private_officer, :trig_closed_foi],
        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_awresp_foi_accepted],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi_accepted],
        [:private_officer, :full_pdacu_foi_unaccepted],
        [:private_officer, :full_ppress_foi],
        [:private_officer, :full_ppress_foi_accepted],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_pprivate_foi_accepted],
        [:private_officer, :full_awdis_foi],
        [:private_officer, :full_responded_foi],
        [:private_officer, :full_closed_foi],
)
    }
  end

  describe :reassign_user do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi],
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :full_awresp_foi],
        [:disclosure_specialist, :full_awresp_foi_accepted],
        [:disclosure_specialist, :full_draft_foi],
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        [:disclosure_specialist, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist, :full_ppress_foi_accepted],
        [:disclosure_specialist, :full_pprivate_foi_accepted],

        [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
        [:disclosure_specialist_coworker, :trig_pdacu_foi],
        [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_awresp_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :full_draft_foi],
        [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist_coworker, :full_ppress_foi_accepted],
        [:disclosure_specialist_coworker, :full_pprivate_foi_accepted],

        [:another_disclosure_specialist, :trig_awresp_foi],
        [:another_disclosure_specialist, :trig_awresp_foi_accepted],
        [:another_disclosure_specialist, :trig_draft_foi],
        [:another_disclosure_specialist, :trig_draft_foi_accepted],
        [:another_disclosure_specialist, :trig_pdacu_foi],
        [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
        [:another_disclosure_specialist, :full_awresp_foi],
        [:another_disclosure_specialist, :full_awresp_foi_accepted],
        [:another_disclosure_specialist, :full_draft_foi],
        [:another_disclosure_specialist, :full_pdacu_foi_accepted],
        [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],

        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :trig_draft_foi],
        [:responder, :trig_draft_foi_accepted],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_pdacu_foi_accepted],
        # [:responder, :trig_awdis_foi], ?
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi_accepted],
        [:responder, :full_pdacu_foi_unaccepted],
        [:responder, :full_ppress_foi],
        [:responder, :full_ppress_foi_accepted],
        [:responder, :full_pprivate_foi],
        [:responder, :full_pprivate_foi_accepted],
        # [:responder, :full_awdis_foi], ?

        [:another_responder_in_same_team, :std_draft_foi],
        [:another_responder_in_same_team, :std_awdis_foi],
        [:another_responder_in_same_team, :trig_draft_foi],
        [:another_responder_in_same_team, :trig_draft_foi_accepted],
        [:another_responder_in_same_team, :trig_pdacu_foi],
        [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
        # [:another_responder_in_same_team, :trig_awdis_foi], ?
        [:another_responder_in_same_team, :full_draft_foi],
        [:another_responder_in_same_team, :full_pdacu_foi_accepted],
        [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
        [:another_responder_in_same_team, :full_ppress_foi],
        [:another_responder_in_same_team, :full_ppress_foi_accepted],
        [:another_responder_in_same_team, :full_pprivate_foi],
        [:another_responder_in_same_team, :full_pprivate_foi_accepted],
        # [:another_responder_in_same_team, :full_awdis_foi], ?

        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_awresp_foi_accepted],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_draft_foi_accepted],
        [:press_officer, :trig_pdacu_foi],
        [:press_officer, :trig_pdacu_foi_accepted],
        # [:press_officer, :trig_awdis_foi], ?
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_awresp_foi_accepted],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi_accepted],
        [:press_officer, :full_pdacu_foi_unaccepted],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_ppress_foi_accepted],
        [:press_officer, :full_pprivate_foi],
        [:press_officer, :full_pprivate_foi_accepted],

        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_awresp_foi_accepted],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_draft_foi_accepted],
        [:private_officer, :trig_pdacu_foi],
        [:private_officer, :trig_pdacu_foi_accepted],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_awresp_foi_accepted],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi_accepted],
        [:private_officer, :full_pdacu_foi_unaccepted],
        [:private_officer, :full_ppress_foi_accepted],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_pprivate_foi_accepted],
  )  }
  end

  describe :reject_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awresp_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_awresp_foi_accepted],
        [:responder, :full_awresp_foi],
        [:responder, :full_awresp_foi_accepted],

        [:another_responder_in_same_team, :std_awresp_foi],
        [:another_responder_in_same_team,:trig_awresp_foi_accepted],
        [:another_responder_in_same_team,:trig_awresp_foi],
        [:another_responder_in_same_team, :full_awresp_foi],
        [:another_responder_in_same_team,:full_awresp_foi_accepted],
      )
    }
  end

  describe :remove_linked_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :std_unassigned_foi],
        [:disclosure_bmt, :std_awresp_foi],
        [:disclosure_bmt, :std_draft_foi],
        [:disclosure_bmt, :std_awdis_foi],
        [:disclosure_bmt, :std_responded_foi],
        [:disclosure_bmt, :trig_unassigned_foi],
        [:disclosure_bmt, :trig_awresp_foi],
        [:disclosure_bmt, :trig_draft_foi],
        [:disclosure_bmt, :trig_pdacu_foi],
        [:disclosure_bmt, :trig_pdacu_foi_accepted],
        [:disclosure_bmt, :trig_awdis_foi],
        [:disclosure_bmt, :trig_responded_foi],
        [:disclosure_bmt, :full_unassigned_foi],
        [:disclosure_bmt, :full_awresp_foi],
        [:disclosure_bmt, :full_draft_foi],
        [:disclosure_bmt, :full_ppress_foi],
        [:disclosure_bmt, :full_pprivate_foi],
        [:disclosure_bmt, :full_awdis_foi],
        [:disclosure_bmt, :full_responded_foi],
        [:disclosure_bmt, :trig_unassigned_foi_accepted],
        [:disclosure_bmt, :trig_awresp_foi_accepted],
        [:disclosure_bmt, :trig_draft_foi_accepted],
        [:disclosure_bmt, :full_awresp_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_accepted],
        [:disclosure_bmt, :full_pdacu_foi_unaccepted],
        [:disclosure_bmt, :full_ppress_foi_accepted],
        [:disclosure_bmt, :full_pprivate_foi_accepted],
        [:disclosure_bmt, :std_closed_foi],
        [:disclosure_bmt, :trig_closed_foi],
        [:disclosure_bmt, :full_closed_foi],

        [:disclosure_specialist, :std_unassigned_foi],
        [:disclosure_specialist, :std_awresp_foi],
        [:disclosure_specialist, :std_draft_foi],
        [:disclosure_specialist, :std_awdis_foi],
        [:disclosure_specialist, :std_responded_foi],
        [:disclosure_specialist, :std_closed_foi],
        [:disclosure_specialist, :trig_unassigned_foi],
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi],
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :trig_awdis_foi],
        [:disclosure_specialist, :trig_responded_foi],
        [:disclosure_specialist, :trig_closed_foi],
        [:disclosure_specialist, :full_unassigned_foi],
        [:disclosure_specialist, :full_awresp_foi],
        [:disclosure_specialist, :full_awresp_foi_accepted],
        [:disclosure_specialist, :full_draft_foi],
        [:disclosure_specialist, :full_pdacu_foi_accepted],
        [:disclosure_specialist, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist, :full_ppress_foi],
        [:disclosure_specialist, :full_ppress_foi_accepted],
        [:disclosure_specialist, :full_pprivate_foi],
        [:disclosure_specialist, :full_pprivate_foi_accepted],
        [:disclosure_specialist, :full_awdis_foi],
        [:disclosure_specialist, :full_responded_foi],
        [:disclosure_specialist, :full_closed_foi],

        [:another_disclosure_specialist, :std_unassigned_foi],
        [:another_disclosure_specialist, :std_awresp_foi],
        [:another_disclosure_specialist, :std_draft_foi],
        [:another_disclosure_specialist, :std_awdis_foi],
        [:another_disclosure_specialist, :std_responded_foi],
        [:another_disclosure_specialist, :std_closed_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
        [:another_disclosure_specialist, :trig_awresp_foi],
        [:another_disclosure_specialist, :trig_awresp_foi_accepted],
        [:another_disclosure_specialist, :trig_draft_foi],
        [:another_disclosure_specialist, :trig_draft_foi_accepted],
        [:another_disclosure_specialist, :trig_pdacu_foi],
        [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
        [:another_disclosure_specialist, :trig_awdis_foi],
        [:another_disclosure_specialist, :trig_responded_foi],
        [:another_disclosure_specialist, :trig_closed_foi],
        [:another_disclosure_specialist, :full_unassigned_foi],
        [:another_disclosure_specialist, :full_awresp_foi],
        [:another_disclosure_specialist, :full_awresp_foi_accepted],
        [:another_disclosure_specialist, :full_draft_foi],
        [:another_disclosure_specialist, :full_pdacu_foi_accepted],
        [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],
        [:another_disclosure_specialist, :full_ppress_foi],
        [:another_disclosure_specialist, :full_ppress_foi_accepted],
        [:another_disclosure_specialist, :full_pprivate_foi],
        [:another_disclosure_specialist, :full_pprivate_foi_accepted],
        [:another_disclosure_specialist, :full_awdis_foi],
        [:another_disclosure_specialist, :full_responded_foi],
        [:another_disclosure_specialist, :full_closed_foi],

        [:disclosure_specialist_coworker, :std_unassigned_foi],
        [:disclosure_specialist_coworker, :std_awresp_foi],
        [:disclosure_specialist_coworker, :std_draft_foi],
        [:disclosure_specialist_coworker, :std_awdis_foi],
        [:disclosure_specialist_coworker, :std_responded_foi],
        [:disclosure_specialist_coworker, :std_closed_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
        [:disclosure_specialist_coworker, :trig_pdacu_foi],
        [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awdis_foi],
        [:disclosure_specialist_coworker, :trig_responded_foi],
        [:disclosure_specialist_coworker, :trig_closed_foi],
        [:disclosure_specialist_coworker, :full_unassigned_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi],
        [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :full_draft_foi],
        [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
        [:disclosure_specialist_coworker, :full_ppress_foi],
        [:disclosure_specialist_coworker, :full_ppress_foi_accepted],
        [:disclosure_specialist_coworker, :full_pprivate_foi],
        [:disclosure_specialist_coworker, :full_pprivate_foi_accepted],
        [:disclosure_specialist_coworker, :full_awdis_foi],
        [:disclosure_specialist_coworker, :full_responded_foi],
        [:disclosure_specialist_coworker, :full_closed_foi],

        [:responder, :std_unassigned_foi],
        [:responder, :std_awresp_foi],
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :std_closed_foi],
        [:responder, :trig_unassigned_foi],
        [:responder, :trig_unassigned_foi_accepted],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_awresp_foi_accepted],
        [:responder, :trig_draft_foi],
        [:responder, :trig_draft_foi_accepted],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_pdacu_foi_accepted],
        [:responder, :trig_awdis_foi],
        [:responder, :trig_responded_foi],
        [:responder, :trig_closed_foi],
        [:responder, :full_unassigned_foi],
        [:responder, :full_awresp_foi],
        [:responder, :full_awresp_foi_accepted],
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi_accepted],
        [:responder, :full_pdacu_foi_unaccepted],
        [:responder, :full_ppress_foi],
        [:responder, :full_ppress_foi_accepted],
        [:responder, :full_pprivate_foi],
        [:responder, :full_pprivate_foi_accepted],
        [:responder, :full_awdis_foi],
        [:responder, :full_responded_foi],
        [:responder, :full_closed_foi],

        [:another_responder_in_same_team, :std_unassigned_foi],
        [:another_responder_in_same_team, :std_awresp_foi],
        [:another_responder_in_same_team, :std_draft_foi],
        [:another_responder_in_same_team, :std_awdis_foi],
        [:another_responder_in_same_team, :std_responded_foi],
        [:another_responder_in_same_team, :std_closed_foi],
        [:another_responder_in_same_team, :trig_unassigned_foi],
        [:another_responder_in_same_team, :trig_unassigned_foi_accepted],
        [:another_responder_in_same_team, :trig_awresp_foi],
        [:another_responder_in_same_team, :trig_awresp_foi_accepted],
        [:another_responder_in_same_team, :trig_draft_foi],
        [:another_responder_in_same_team, :trig_draft_foi_accepted],
        [:another_responder_in_same_team, :trig_pdacu_foi],
        [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
        [:another_responder_in_same_team, :trig_awdis_foi],
        [:another_responder_in_same_team, :trig_responded_foi],
        [:another_responder_in_same_team, :trig_closed_foi],
        [:another_responder_in_same_team, :full_unassigned_foi],
        [:another_responder_in_same_team, :full_awresp_foi],
        [:another_responder_in_same_team, :full_awresp_foi_accepted],
        [:another_responder_in_same_team, :full_draft_foi],
        [:another_responder_in_same_team, :full_pdacu_foi_accepted],
        [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
        [:another_responder_in_same_team, :full_ppress_foi],
        [:another_responder_in_same_team, :full_ppress_foi_accepted],
        [:another_responder_in_same_team, :full_pprivate_foi],
        [:another_responder_in_same_team, :full_pprivate_foi_accepted],
        [:another_responder_in_same_team, :full_awdis_foi],
        [:another_responder_in_same_team, :full_responded_foi],
        [:another_responder_in_same_team, :full_closed_foi],

        [:another_responder_in_diff_team, :std_unassigned_foi],
        [:another_responder_in_diff_team, :std_awresp_foi],
        [:another_responder_in_diff_team, :std_draft_foi],
        [:another_responder_in_diff_team, :std_awdis_foi],
        [:another_responder_in_diff_team, :std_responded_foi],
        [:another_responder_in_diff_team, :std_closed_foi],
        [:another_responder_in_diff_team, :trig_unassigned_foi],
        [:another_responder_in_diff_team, :trig_unassigned_foi_accepted],
        [:another_responder_in_diff_team, :trig_awresp_foi],
        [:another_responder_in_diff_team, :trig_awresp_foi_accepted],
        [:another_responder_in_diff_team, :trig_draft_foi],
        [:another_responder_in_diff_team, :trig_draft_foi_accepted],
        [:another_responder_in_diff_team, :trig_pdacu_foi],
        [:another_responder_in_diff_team, :trig_pdacu_foi_accepted],
        [:another_responder_in_diff_team, :trig_awdis_foi],
        [:another_responder_in_diff_team, :trig_responded_foi],
        [:another_responder_in_diff_team, :trig_closed_foi],
        [:another_responder_in_diff_team, :full_unassigned_foi],
        [:another_responder_in_diff_team, :full_awresp_foi],
        [:another_responder_in_diff_team, :full_awresp_foi_accepted],
        [:another_responder_in_diff_team, :full_draft_foi],
        [:another_responder_in_diff_team, :full_pdacu_foi_accepted],
        [:another_responder_in_diff_team, :full_pdacu_foi_unaccepted],
        [:another_responder_in_diff_team, :full_ppress_foi],
        [:another_responder_in_diff_team, :full_ppress_foi_accepted],
        [:another_responder_in_diff_team, :full_pprivate_foi],
        [:another_responder_in_diff_team, :full_pprivate_foi_accepted],
        [:another_responder_in_diff_team, :full_awdis_foi],
        [:another_responder_in_diff_team, :full_responded_foi],
        [:another_responder_in_diff_team, :full_closed_foi],

        [:press_officer, :std_unassigned_foi],
        [:press_officer, :std_awresp_foi],
        [:press_officer, :std_draft_foi],
        [:press_officer, :std_awdis_foi],
        [:press_officer, :std_responded_foi],
        [:press_officer, :std_closed_foi],
        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_unassigned_foi_accepted],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_awresp_foi_accepted],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_draft_foi_accepted],
        [:press_officer, :trig_pdacu_foi],
        [:press_officer, :trig_pdacu_foi_accepted],
        [:press_officer, :trig_awdis_foi],
        [:press_officer, :trig_responded_foi],
        [:press_officer, :trig_closed_foi],
        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_awresp_foi_accepted],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi_accepted],
        [:press_officer, :full_pdacu_foi_unaccepted],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_ppress_foi_accepted],
        [:press_officer, :full_pprivate_foi],
        [:press_officer, :full_pprivate_foi_accepted],
        [:press_officer, :full_awdis_foi],
        [:press_officer, :full_responded_foi],
        [:press_officer, :full_closed_foi],

        [:private_officer, :std_unassigned_foi],
        [:private_officer, :std_awresp_foi],
        [:private_officer, :std_draft_foi],
        [:private_officer, :std_awdis_foi],
        [:private_officer, :std_responded_foi],
        [:private_officer, :std_closed_foi],
        [:private_officer, :trig_unassigned_foi],
        [:private_officer, :trig_unassigned_foi_accepted],
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_awresp_foi_accepted],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_draft_foi_accepted],
        [:private_officer, :trig_pdacu_foi],
        [:private_officer, :trig_pdacu_foi_accepted],
        [:private_officer, :trig_awdis_foi],
        [:private_officer, :trig_responded_foi],
        [:private_officer, :trig_closed_foi],
        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_awresp_foi_accepted],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi_accepted],
        [:private_officer, :full_pdacu_foi_unaccepted],
        [:private_officer, :full_ppress_foi],
        [:private_officer, :full_ppress_foi_accepted],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_pprivate_foi_accepted],
        [:private_officer, :full_awdis_foi],
        [:private_officer, :full_responded_foi],
        [:private_officer, :full_closed_foi],
)    }
  end

  describe :remove_response do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awdis_foi],
        [:responder, :trig_awdis_foi],
        [:responder, :full_awdis_foi],
        [:another_responder_in_same_team, :std_awdis_foi],
        [:another_responder_in_same_team, :trig_awdis_foi],
        [:another_responder_in_same_team, :full_awdis_foi],
        )}
  end

  describe :request_amends do
    it {
      should permit_event_to_be_triggered_only_by(
        # [:press_officer, :full_ppress_foi_accepted], should be allowed, controlled by old state_machine
        # [:private_officer, :full_pprivate_foi_accepted] should be allowed, controlled by old state_machine
      )}
  end


  describe :request_further_clearance do
    it {should permit_event_to_be_triggered_only_by(
      [:disclosure_bmt, :std_unassigned_foi],
      [:disclosure_bmt, :std_awresp_foi],
      [:disclosure_bmt, :std_draft_foi],
      [:disclosure_bmt, :std_awdis_foi],
      [:disclosure_bmt, :trig_unassigned_foi],
      [:disclosure_bmt, :trig_awresp_foi],
      [:disclosure_bmt, :trig_draft_foi],
      [:disclosure_bmt, :trig_pdacu_foi],
      [:disclosure_bmt, :trig_awdis_foi],
      [:disclosure_bmt, :trig_unassigned_foi_accepted],
      [:disclosure_bmt, :trig_awresp_foi_accepted],
      [:disclosure_bmt, :trig_draft_foi_accepted],
      [:disclosure_bmt, :trig_pdacu_foi_accepted],

      # the following are permitted by the old state machine but shouldn't be

      [:disclosure_specialist, :trig_awdis_foi],                            # old state machine - they shouldn't be allowed
      [:another_disclosure_specialist, :trig_awdis_foi],                    # old state machine - they shouldn't be allowed
      [:disclosure_specialist_coworker, :trig_awdis_foi],                   # old state machine - they shouldn't be allowed
      [:responder, :trig_awdis_foi],                           # old state machine - they shouldn't be allowed
      [:another_responder_in_same_team, :trig_awdis_foi],      # old state machine - they shouldn't be allowed
      [:another_responder_in_diff_team, :trig_awdis_foi],      # old state machine - they shouldn't be allowed
      [:press_officer, :trig_awdis_foi],                       # old state machine - they shouldn't be allowed
      [:private_officer, :trig_awdis_foi],                     # old state machine - they shouldn't be allowed
    )
    }
  end

  describe :respond do
    it {
      should permit_event_to_be_triggered_only_by(
      [:responder, :std_awdis_foi],
      [:responder, :trig_awdis_foi],
      [:responder, :full_awdis_foi],
      [:another_responder_in_same_team, :std_awdis_foi],
      [:another_responder_in_same_team, :trig_awdis_foi],
      [:another_responder_in_same_team, :full_awdis_foi],
      )}
  end

  describe :take_on_for_approval do
    it {
      should permit_event_to_be_triggered_only_by(
        [:press_officer, :std_unassigned_foi],
        [:press_officer, :std_awresp_foi],
        [:press_officer, :std_draft_foi],
        [:press_officer, :std_awdis_foi],
        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_unassigned_foi_accepted],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_awresp_foi_accepted],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_draft_foi_accepted],
        [:press_officer, :trig_awdis_foi],

        [:private_officer, :std_unassigned_foi],
        [:private_officer, :std_awresp_foi],
        [:private_officer, :std_draft_foi],
        [:private_officer, :std_awdis_foi],
        [:private_officer, :trig_unassigned_foi],
        [:private_officer, :trig_unassigned_foi_accepted],
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_awresp_foi_accepted],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_draft_foi_accepted],
        [:private_officer, :trig_awdis_foi],
# another approver and approver are permitted here since the policy allows
# any team that has not taken the case on to take it on
        [:another_disclosure_specialist, :std_unassigned_foi],
        [:another_disclosure_specialist, :std_awresp_foi],
        [:another_disclosure_specialist, :std_draft_foi],
        [:another_disclosure_specialist, :std_awdis_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi],
        [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
        [:another_disclosure_specialist, :trig_awresp_foi],
        [:another_disclosure_specialist, :trig_awresp_foi_accepted],
        [:another_disclosure_specialist, :trig_draft_foi],
        [:another_disclosure_specialist, :trig_draft_foi_accepted],
        [:another_disclosure_specialist, :trig_awdis_foi],
        [:another_disclosure_specialist, :full_unassigned_foi],
        [:another_disclosure_specialist, :full_awresp_foi],
        [:another_disclosure_specialist, :full_awresp_foi_accepted],
        [:another_disclosure_specialist, :full_draft_foi],
        [:another_disclosure_specialist, :full_awdis_foi],

        [:disclosure_specialist_coworker, :std_unassigned_foi],
        [:disclosure_specialist_coworker, :std_awresp_foi],
        [:disclosure_specialist_coworker, :std_draft_foi],
        [:disclosure_specialist_coworker, :std_awdis_foi],

        [:disclosure_specialist, :std_unassigned_foi],
        [:disclosure_specialist, :std_awresp_foi],
        [:disclosure_specialist, :std_draft_foi],
        [:disclosure_specialist, :std_awdis_foi],

  )  }
  end

  describe :unaccept_approver_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :trig_awdis_foi], # don't think this should be here controlledby old state_machine)
    )}
  end

  describe :unflag_for_clearance do
    it {
      should permit_event_to_be_triggered_only_by(
        [:disclosure_bmt, :trig_awdis_foi],                    # old state machine allows but shouldn't
        [:disclosure_bmt, :full_awdis_foi],                    # old state machine allows but shouldn't

        [:disclosure_specialist, :trig_unassigned_foi],
        [:disclosure_specialist, :trig_unassigned_foi_accepted],
        [:disclosure_specialist, :trig_awresp_foi],
        [:disclosure_specialist, :trig_awresp_foi_accepted],
        [:disclosure_specialist, :trig_draft_foi],
        [:disclosure_specialist, :trig_draft_foi_accepted],
        [:disclosure_specialist, :trig_pdacu_foi],
        [:disclosure_specialist, :trig_awdis_foi],                  # old state machine allows but shouldn't
        [:disclosure_specialist, :trig_pdacu_foi_accepted],
        [:disclosure_specialist, :full_awdis_foi],                   # old state machine allows but shouldn't

        [:disclosure_specialist_coworker, :trig_unassigned_foi],
        [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
        [:disclosure_specialist_coworker, :trig_awresp_foi],
        [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
        [:disclosure_specialist_coworker, :trig_draft_foi],
        [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
        [:disclosure_specialist_coworker, :trig_pdacu_foi],
        [:disclosure_specialist_coworker, :trig_awdis_foi],                  # old state machine allows but shouldn't
        [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
        [:disclosure_specialist_coworker, :full_awdis_foi],                   # old state machine allows but shouldn't


        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_awresp_foi_accepted],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi_accepted],
        [:press_officer, :full_pdacu_foi_unaccepted],

        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_awresp_foi_accepted],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi_accepted],
        [:private_officer, :full_pdacu_foi_unaccepted],
        )
    }
  end

  describe :upload_response_and_approve do
    it {
      should permit_event_to_be_triggered_only_by(
       [:disclosure_specialist, :full_pdacu_foi_accepted],
       [:disclosure_specialist, :trig_pdacu_foi_accepted],
     )
    }
  end

  describe :upload_response_and_return_for_redraft do
    it {
      should permit_event_to_be_triggered_only_by(
       [:disclosure_specialist, :full_pdacu_foi_accepted],
       [:disclosure_specialist, :trig_pdacu_foi_accepted],
     )
    }
  end

  describe :upload_response_approve_and_bypass do
    it {
      should permit_event_to_be_triggered_only_by(
         [:disclosure_specialist, :full_pdacu_foi_accepted],
       )
    }
  end



  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

end
