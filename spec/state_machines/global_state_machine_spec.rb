
require 'rails_helper'

describe 'state machine' do

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new
  end

  after(:all) { DbHousekeeping.clean }

  describe :accept_approver_assignment do
    it {
      expect(1).to eq 1
      should permit_event_to_be_triggered_only_by(
        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :full_unassigned_foi],
        [:approver, :full_awresp_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_awdis_foi],         # standard state machine wrongly allowing this - remove when converting to config state machine
        [:approver, :full_responded_foi],     # standard state machine wrongly allowing this - remove when converting to config state machine

        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi],
        [:private_officer, :full_awdis_foi],        # standard state machine wrongly allowing this - remove when converting to config state machine
        [:private_officer, :full_responded_foi],    # standard state machine wrongly allowing this - remove when converting to config state machine

        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi],
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
        [:manager, :std_unassigned_foi],
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :std_awdis_foi],
        [:manager, :std_responded_foi],
        [:manager, :trig_unassigned_foi],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_draft_foi],
        [:manager, :trig_pdacu_foi],
        [:manager, :trig_awdis_foi],
        [:manager, :trig_responded_foi],
        [:manager, :full_unassigned_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_draft_foi],
        [:manager, :full_pdacu_foi],
        [:manager, :full_ppress_foi],
        [:manager, :full_pprivate_foi],
        [:manager, :full_awdis_foi],
        [:manager, :full_responded_foi],
        [:manager, :trig_unassigned_foi_accepted],
        [:manager, :trig_awresp_foi_accepted],
        [:manager, :trig_draft_foi_accepted],
        [:manager, :trig_pdacu_foi_accepted],
        [:manager, :full_awresp_foi_accepted],
        [:manager, :full_pdacu_foi_accepted],
        [:manager, :full_ppress_foi_accepted],
        [:manager, :full_pprivate_foi_accepted],


        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :trig_awdis_foi],
        [:approver, :trig_responded_foi],
        [:approver, :trig_unassigned_foi_accepted],
        [:approver, :trig_awresp_foi_accepted],
        [:approver, :trig_draft_foi_accepted],
        [:approver, :trig_pdacu_foi_accepted],
        [:approver, :full_awresp_foi_accepted],
        [:approver, :full_unassigned_foi],
        [:approver, :full_awresp_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_pdacu_foi],
        [:approver, :full_ppress_foi],
        [:approver, :full_pprivate_foi],
        [:approver, :full_awdis_foi],
        [:approver, :full_responded_foi],
        [:approver, :full_pdacu_foi_accepted],
        [:approver, :full_ppress_foi_accepted],
        [:approver, :full_pprivate_foi_accepted],



        [:another_approver, :trig_unassigned_foi],
        [:another_approver, :trig_awresp_foi],
        [:another_approver, :trig_draft_foi],
        [:another_approver, :trig_pdacu_foi],
        # [:another_approver, :trig_awdis_foi],           # old state machine - they should be allowed
        # [:another_approver, :trig_responded_foi],        # old state machine - they should be allowed
        [:another_approver, :trig_unassigned_foi_accepted],
        [:another_approver, :trig_awresp_foi_accepted],
        [:another_approver, :trig_draft_foi_accepted],
        [:another_approver, :trig_pdacu_foi_accepted],

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
        [:responder, :full_pdacu_foi],
        [:responder, :full_ppress_foi],
        [:responder, :full_pprivate_foi],
        [:responder, :full_awdis_foi],
        # [:responder, :full_responded_foi],          # old state machine - they should be allowed
        [:responder, :full_pdacu_foi_accepted],
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
        [:another_responder_in_same_team, :full_pdacu_foi],
        [:another_responder_in_same_team, :full_ppress_foi],
        [:another_responder_in_same_team, :full_pprivate_foi],
        [:another_responder_in_same_team, :full_awdis_foi],
        # [:another_responder_in_same_team, :full_responded_foi],        # old state machine - they should be allowed
        [:another_responder_in_same_team, :full_pdacu_foi_accepted],
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
        [:press_officer, :full_pdacu_foi],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_pprivate_foi],
        [:press_officer, :full_awdis_foi],
        [:press_officer, :full_responded_foi],
        [:press_officer, :full_pdacu_foi_accepted],
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
        [:private_officer, :full_pdacu_foi],
        [:private_officer, :full_ppress_foi],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_awdis_foi],
        [:private_officer, :full_responded_foi],
        [:private_officer, :full_pdacu_foi_accepted],
        [:private_officer, :full_ppress_foi_accepted],
        [:private_officer, :full_pprivate_foi_accepted],

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
        [:approver, :trig_pdacu_foi_accepted],
        [:approver, :full_pdacu_foi_accepted],
        # [:press_officer, :full_ppress_foi_accepted],          # old state machine - they should be allowed
        # [:private_officer, :full_pprivate_foi_accepted],      # old state machine - they should be allowed
        )}
  end

  describe :approve_and_bypass do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :full_pdacu_foi_accepted],
        )}
  end

  describe :assign_responder do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
        [:manager, :trig_unassigned_foi_accepted],
        [:manager, :trig_unassigned_foi],
        [:manager, :full_unassigned_foi],
        )}
  end

  describe :assign_to_new_team do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_awresp_foi_accepted],
        [:manager, :trig_draft_foi],
        [:manager, :trig_draft_foi_accepted],
        [:manager, :full_awresp_foi],
        [:manager, :full_awresp_foi_accepted],
        [:manager, :full_draft_foi],
        )}
  end

  describe :close do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_responded_foi],
        [:manager, :trig_responded_foi],
        [:manager, :full_responded_foi],
        )}
  end

  describe :destroy_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :std_awdis_foi],
        [:manager, :std_responded_foi],
        [:manager, :std_closed_foi],
        [:manager, :trig_unassigned_foi],
        [:manager, :trig_unassigned_foi_accepted],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_awresp_foi_accepted],
        [:manager, :trig_draft_foi],
        [:manager, :trig_draft_foi_accepted],
        [:manager, :trig_pdacu_foi],
        [:manager, :trig_pdacu_foi_accepted],
        [:manager, :trig_awdis_foi],
        [:manager, :trig_responded_foi],
        [:manager, :trig_closed_foi],
        [:manager, :full_unassigned_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_awresp_foi_accepted],
        [:manager, :full_draft_foi],
        [:manager, :full_pdacu_foi],
        [:manager, :full_pdacu_foi_accepted],
        [:manager, :full_ppress_foi],
        [:manager, :full_ppress_foi_accepted],
        [:manager, :full_pprivate_foi],
        [:manager, :full_pprivate_foi_accepted],
        [:manager, :full_awdis_foi],
        [:manager, :full_responded_foi],
        [:manager, :full_closed_foi]
        )}
  end

  describe :edit_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :std_awdis_foi],
        [:manager, :std_responded_foi],
        [:manager, :std_closed_foi],
        [:manager, :trig_unassigned_foi],
        [:manager, :trig_unassigned_foi_accepted],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_awresp_foi_accepted],
        [:manager, :trig_draft_foi],
        [:manager, :trig_draft_foi_accepted],
        [:manager, :trig_pdacu_foi],
        [:manager, :trig_pdacu_foi_accepted],
        [:manager, :trig_awdis_foi],
        [:manager, :trig_responded_foi],
        [:manager, :trig_closed_foi],
        [:manager, :full_unassigned_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_awresp_foi_accepted],
        [:manager, :full_draft_foi],
        [:manager, :full_pdacu_foi],
        [:manager, :full_pdacu_foi_accepted],
        [:manager, :full_ppress_foi],
        [:manager, :full_ppress_foi_accepted],
        [:manager, :full_pprivate_foi],
        [:manager, :full_pprivate_foi_accepted],
        [:manager, :full_awdis_foi],
        [:manager, :full_responded_foi],
        [:manager, :full_closed_foi]
        )}
  end

  xdescribe :extend_for_pit do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :trig_awdis_foi],
        [:approver, :trig_responded_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_pdacu_foi],
        [:approver, :full_awdis_foi],
        [:approver, :full_responded_foi],
        )}
  end

  xdescribe :flag_for_clearance do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :std_awdis_foi],
        [:manager, :trig_unassigned_foi],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_draft_foi],
        [:manager, :trig_pdacu_foi],
        [:manager, :trig_awdis_foi],
        [:manager, :full_unassigned_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_draft_foi],
        [:manager, :full_awdis_foi],

        [:approver, :std_unassigned_foi],
        [:approver, :std_awresp_foi],
        [:approver, :std_draft_foi],
        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        )}
  end

  xdescribe :link_a_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :std_awdis_foi],
        [:manager, :std_responded_foi],
        [:manager, :std_closed_foi],
        [:manager, :trig_unassigned_foi],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_draft_foi],
        [:manager, :trig_pdacu_foi],
        [:manager, :trig_awdis_foi],
        [:manager, :trig_responded_foi],
        [:manager, :trig_closed_foi],
        [:manager, :full_unassigned_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_draft_foi],
        [:manager, :full_pdacu_foi],
        [:manager, :full_ppress_foi],
        [:manager, :full_pprivate_foi],
        [:manager, :full_awdis_foi],
        [:manager, :full_responded_foi],
        [:manager, :full_closed_foi],

        [:approver, :std_unassigned_foi],
        [:approver, :std_awresp_foi],
        [:approver, :std_draft_foi],
        [:approver, :std_awdis_foi],
        [:approver, :std_responded_foi],
        [:approver, :std_closed_foi],
        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :trig_awdis_foi],
        [:approver, :trig_responded_foi],
        [:approver, :trig_closed_foi],
        [:approver, :full_unassigned_foi],
        [:approver, :full_awresp_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_pdacu_foi],
        [:approver, :full_ppress_foi],
        [:approver, :full_pprivate_foi],
        [:approver, :full_awdis_foi],
        [:approver, :full_responded_foi],
        [:approver, :full_closed_foi],

        [:another_approver, :std_unassigned_foi],
        [:another_approver, :std_awresp_foi],
        [:another_approver, :std_draft_foi],
        [:another_approver, :std_awdis_foi],
        [:another_approver, :std_responded_foi],
        [:another_approver, :std_closed_foi],
        [:another_approver, :trig_unassigned_foi],
        [:another_approver, :trig_awresp_foi],
        [:another_approver, :trig_draft_foi],
        [:another_approver, :trig_pdacu_foi],
        [:another_approver, :trig_awdis_foi],
        [:another_approver, :trig_responded_foi],
        [:another_approver, :trig_closed_foi],
        [:another_approver, :full_unassigned_foi],
        [:another_approver, :full_awresp_foi],
        [:another_approver, :full_draft_foi],
        [:another_approver, :full_pdacu_foi],
        [:another_approver, :full_ppress_foi],
        [:another_approver, :full_pprivate_foi],
        [:another_approver, :full_awdis_foi],
        [:another_approver, :full_responded_foi],
        [:another_approver, :full_closed_foi],

        [:press_officer, :std_unassigned_foi],
        [:press_officer, :std_awresp_foi],
        [:press_officer, :std_draft_foi],
        [:press_officer, :std_awdis_foi],
        [:press_officer, :std_responded_foi],
        [:press_officer, :std_closed_foi],
        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_pdacu_foi],
        [:press_officer, :trig_awdis_foi],
        [:press_officer, :trig_responded_foi],
        [:press_officer, :trig_closed_foi],
        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_pprivate_foi],
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
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_pdacu_foi],
        [:private_officer, :trig_awdis_foi],
        [:private_officer, :trig_responded_foi],
        [:private_officer, :trig_closed_foi],
        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi],
        [:private_officer, :full_ppress_foi],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_awdis_foi],
        [:private_officer, :full_responded_foi],
        [:private_officer, :full_closed_foi],

        [:responder, :std_unassigned_foi],
        [:responder, :std_awresp_foi],
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :std_closed_foi],
        [:responder, :trig_unassigned_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_draft_foi],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_awdis_foi],
        [:responder, :trig_responded_foi],
        [:responder, :trig_closed_foi],
        [:responder, :full_unassigned_foi],
        [:responder, :full_awresp_foi],
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi],
        [:responder, :full_ppress_foi],
        [:responder, :full_pprivate_foi],
        [:responder, :full_awdis_foi],
        [:responder, :full_responded_foi],
        [:responder, :full_closed_foi],

        [:another_responder, :std_unassigned_foi],
        [:another_responder, :std_awresp_foi],
        [:another_responder, :std_draft_foi],
        [:another_responder, :std_awdis_foi],
        [:another_responder, :std_responded_foi],
        [:another_responder, :std_closed_foi],
        [:another_responder, :trig_unassigned_foi],
        [:another_responder, :trig_awresp_foi],
        [:another_responder, :trig_draft_foi],
        [:another_responder, :trig_pdacu_foi],
        [:another_responder, :trig_awdis_foi],
        [:another_responder, :trig_responded_foi],
        [:another_responder, :trig_closed_foi],
        [:another_responder, :full_unassigned_foi],
        [:another_responder, :full_awresp_foi],
        [:another_responder, :full_draft_foi],
        [:another_responder, :full_pdacu_foi],
        [:another_responder, :full_ppress_foi],
        [:another_responder, :full_pprivate_foi],
        [:another_responder, :full_awdis_foi],
        [:another_responder, :full_responded_foi],
        [:another_responder, :full_closed_foi])
    }
  end

  xdescribe :reassign_user do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :trig_awdis_foi],
        [:approver, :trig_responded_foi],
        [:approver, :full_unassigned_foi],
        [:approver, :full_awresp_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_pdacu_foi],
        [:approver, :full_ppress_foi],
        [:approver, :full_pprivate_foi],
        [:approver, :full_awdis_foi],
        [:approver, :full_responded_foi],

        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :trig_draft_foi],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_awdis_foi],
        [:responder, :trig_responded_foi],
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi],
        [:responder, :full_ppress_foi],
        [:responder, :full_pprivate_foi],
        [:responder, :full_awdis_foi],
        [:responder, :full_responded_foi],

        [:press_officer, :press_office, :trig_unassigned_foi],
        [:press_officer, :press_office, :trig_awresp_foi],
        [:press_officer, :press_office, :trig_draft_foi],
        [:press_officer, :press_office, :trig_pdacu_foi],
        [:press_officer, :press_office, :trig_awdis_foi],
        [:press_officer, :press_office, :trig_responded_foi],
        [:press_officer, :press_office, :full_unassigned_foi],
        [:press_officer, :press_office, :full_awresp_foi],
        [:press_officer, :press_office, :full_draft_foi],
        [:press_officer, :press_office, :full_pdacu_foi],
        [:press_officer, :press_office, :full_ppress_foi],
        [:press_officer, :press_office, :full_pprivate_foi],
        [:press_officer, :press_office, :full_awdis_foi],
        [:press_officer, :press_office, :full_responded_foi],

        [:private_officer, :private_office, :trig_unassigned_foi],
        [:private_officer, :private_office, :trig_awresp_foi],
        [:private_officer, :private_office, :trig_draft_foi],
        [:private_officer, :private_office, :trig_pdacu_foi],
        [:private_officer, :private_office, :trig_awdis_foi],
        [:private_officer, :private_office, :trig_responded_foi],
        [:private_officer, :private_office, :full_unassigned_foi],
        [:private_officer, :private_office, :full_awresp_foi],
        [:private_officer, :private_office, :full_draft_foi],
        [:private_officer, :private_office, :full_pdacu_foi],
        [:private_officer, :private_office, :full_ppress_foi],
        [:private_officer, :private_office, :full_pprivate_foi],
        [:private_officer, :private_office, :full_awdis_foi],
        [:private_officer, :private_office, :full_responded_foi],
  )  }
  end

  xdescribe :reject_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awresp_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :full_awresp_foi]
      )
    }
  end

  xdescribe :remove_linked_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
        [:manager, :std_awresp_foi],
        [:manager, :std_draft_foi],
        [:manager, :std_awdis_foi],
        [:manager, :std_responded_foi],
        [:manager, :std_closed_foi],
        [:manager, :trig_unassigned_foi],
        [:manager, :trig_awresp_foi],
        [:manager, :trig_draft_foi],
        [:manager, :trig_pdacu_foi],
        [:manager, :trig_awdis_foi],
        [:manager, :trig_responded_foi],
        [:manager, :trig_closed_foi],
        [:manager, :full_unassigned_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_draft_foi],
        [:manager, :full_pdacu_foi],
        [:manager, :full_ppress_foi],
        [:manager, :full_pprivate_foi],
        [:manager, :full_awdis_foi],
        [:manager, :full_responded_foi],
        [:manager, :full_closed_foi],

        [:approver, :std_unassigned_foi],
        [:approver, :std_awresp_foi],
        [:approver, :std_draft_foi],
        [:approver, :std_awdis_foi],
        [:approver, :std_responded_foi],
        [:approver, :std_closed_foi],
        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :trig_awdis_foi],
        [:approver, :trig_responded_foi],
        [:approver, :trig_closed_foi],
        [:approver, :full_unassigned_foi],
        [:approver, :full_awresp_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_pdacu_foi],
        [:approver, :full_ppress_foi],
        [:approver, :full_pprivate_foi],
        [:approver, :full_awdis_foi],
        [:approver, :full_responded_foi],
        [:approver, :full_closed_foi],

        [:another_approver, :std_unassigned_foi],
        [:another_approver, :std_awresp_foi],
        [:another_approver, :std_draft_foi],
        [:another_approver, :std_awdis_foi],
        [:another_approver, :std_responded_foi],
        [:another_approver, :std_closed_foi],
        [:another_approver, :trig_unassigned_foi],
        [:another_approver, :trig_awresp_foi],
        [:another_approver, :trig_draft_foi],
        [:another_approver, :trig_pdacu_foi],
        [:another_approver, :trig_awdis_foi],
        [:another_approver, :trig_responded_foi],
        [:another_approver, :trig_closed_foi],
        [:another_approver, :full_unassigned_foi],
        [:another_approver, :full_awresp_foi],
        [:another_approver, :full_draft_foi],
        [:another_approver, :full_pdacu_foi],
        [:another_approver, :full_ppress_foi],
        [:another_approver, :full_pprivate_foi],
        [:another_approver, :full_awdis_foi],
        [:another_approver, :full_responded_foi],
        [:another_approver, :full_closed_foi],

        [:press_officer, :std_unassigned_foi],
        [:press_officer, :std_awresp_foi],
        [:press_officer, :std_draft_foi],
        [:press_officer, :std_awdis_foi],
        [:press_officer, :std_responded_foi],
        [:press_officer, :std_closed_foi],
        [:press_officer, :trig_unassigned_foi],
        [:press_officer, :trig_awresp_foi],
        [:press_officer, :trig_draft_foi],
        [:press_officer, :trig_pdacu_foi],
        [:press_officer, :trig_awdis_foi],
        [:press_officer, :trig_responded_foi],
        [:press_officer, :trig_closed_foi],
        [:press_officer, :full_unassigned_foi],
        [:press_officer, :full_awresp_foi],
        [:press_officer, :full_draft_foi],
        [:press_officer, :full_pdacu_foi],
        [:press_officer, :full_ppress_foi],
        [:press_officer, :full_pprivate_foi],
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
        [:private_officer, :trig_awresp_foi],
        [:private_officer, :trig_draft_foi],
        [:private_officer, :trig_pdacu_foi],
        [:private_officer, :trig_awdis_foi],
        [:private_officer, :trig_responded_foi],
        [:private_officer, :trig_closed_foi],
        [:private_officer, :full_unassigned_foi],
        [:private_officer, :full_awresp_foi],
        [:private_officer, :full_draft_foi],
        [:private_officer, :full_pdacu_foi],
        [:private_officer, :full_ppress_foi],
        [:private_officer, :full_pprivate_foi],
        [:private_officer, :full_awdis_foi],
        [:private_officer, :full_responded_foi],
        [:private_officer, :full_closed_foi],

        [:responder, :std_unassigned_foi],
        [:responder, :std_awresp_foi],
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :std_closed_foi],
        [:responder, :trig_unassigned_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_draft_foi],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_awdis_foi],
        [:responder, :trig_responded_foi],
        [:responder, :trig_closed_foi],
        [:responder, :full_unassigned_foi],
        [:responder, :full_awresp_foi],
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi],
        [:responder, :full_ppress_foi],
        [:responder, :full_pprivate_foi],
        [:responder, :full_awdis_foi],
        [:responder, :full_responded_foi],
        [:responder, :full_closed_foi],

        [:another_responder, :std_unassigned_foi],
        [:another_responder, :std_awresp_foi],
        [:another_responder, :std_draft_foi],
        [:another_responder, :std_awdis_foi],
        [:another_responder, :std_responded_foi],
        [:another_responder, :std_closed_foi],
        [:another_responder, :trig_unassigned_foi],
        [:another_responder, :trig_awresp_foi],
        [:another_responder, :trig_draft_foi],
        [:another_responder, :trig_pdacu_foi],
        [:another_responder, :trig_awdis_foi],
        [:another_responder, :trig_responded_foi],
        [:another_responder, :trig_closed_foi],
        [:another_responder, :full_unassigned_foi],
        [:another_responder, :full_awresp_foi],
        [:another_responder, :full_draft_foi],
        [:another_responder, :full_pdacu_foi],
        [:another_responder, :full_ppress_foi],
        [:another_responder, :full_pprivate_foi],
        [:another_responder, :full_awdis_foi],
        [:another_responder, :full_responded_foi],
        [:another_responder, :full_closed_foi])
    }
  end

  xdescribe :remove_response do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awdis_foi,]
        )}
  end

  xdescribe :request_amends do
    it {
      should permit_event_to_be_triggered_only_by(
        [:press_officer, :press_office, :full_ppress_foi],
        [:private_officer, :private_office, :full_pprivate_foi]
      )}
  end


  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

end
