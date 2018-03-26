
require 'rails_helper'

# require_relative '../support/standard_setup.rb'

describe Case::FOI::StandardStateMachine do

  before(:all) do
    DbHousekeeping.clean
    @setup = StandardSetup.new
  end

  after(:all) { DbHousekeeping.clean }


  describe :accept_approver_assignment do
    it {
      expect(1).to eq 1
      should permit_event_to_be_triggered_only_by(
        [:approver, :std_unassigned_foi],
        [:approver, :std_awresp_foi],
        [:approver, :std_draft_foi],
        [:approver, :trig_unassigned_foi],
        [:approver, :trig_awresp_foi],
        [:approver, :trig_draft_foi],
        [:approver, :trig_pdacu_foi],
        [:approver, :full_unassigned_foi],
        [:approver, :full_awresp_foi],
        [:approver, :full_draft_foi],
        [:approver, :full_pdacu_foi],
      )
    }
  end

  describe :accept_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awresp_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :full_awresp_foi],
        [:another_responder_in_same_team, :std_awresp_foi],
        [:another_responder_in_same_team, :trig_awresp_foi],
        [:another_responder_in_same_team, :full_awresp_foi]
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

        [:approver, :std_unassigned_foi],
        [:approver, :std_awresp_foi],
        [:approver, :std_draft_foi],
        [:approver, :std_awdis_foi],
        [:approver, :std_responded_foi],
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

        [:responder, :std_unassigned_foi],
        [:responder, :std_awresp_foi],
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        [:responder, :std_responded_foi],
        [:responder, :trig_unassigned_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :trig_draft_foi],
        [:responder, :trig_pdacu_foi],
        [:responder, :trig_awdis_foi],
        [:responder, :trig_responded_foi],
        [:responder, :full_unassigned_foi],
        [:responder, :full_awresp_foi],
        [:responder, :full_draft_foi],
        [:responder, :full_pdacu_foi],
        [:responder, :full_ppress_foi],
        [:responder, :full_pprivate_foi],
        [:responder, :full_awdis_foi],
        [:responder, :full_responded_foi])
    }
  end

  describe :add_response_to_flagged_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :trig_draft_foi],
        [:responder, :full_draft_foi],
        [:another_responder_in_same_team, :trig_responded_foi],
        [:another_responder_in_same_team, :full_draft_foi]
        )}
  end

  describe :add_responses do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_draft_foi],
        [:responder, :std_awdis_foi],
        )}
  end

  describe :approve do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :trig_pdacu_foi],
        [:approver, :full_pdacu_foi],
        [:press_officer, :full_ppress_foi],
        [:private_officer, :full_pprivate_foi],
        )}
  end

  describe :approve_and_bypass do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :full_pdacu_foi],
        )}
  end

  describe :assign_responder do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_unassigned_foi],
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
        [:manager, :trig_draft_foi],
        [:manager, :full_awresp_foi],
        [:manager, :full_draft_foi],
        )}
  end

  describe :close do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :std_awdis_foi],
        [:manager, :trig_awdis_foi],
        [:manager, :full_awdis_foi],
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
        [:manager, :full_closed_foi]
        )}
  end

  describe :extend_for_pit do
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

  describe :flag_for_clearance do
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

  describe :link_a_case do
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

  describe :reassign_user do
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

  describe :reject_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awresp_foi],
        [:responder, :trig_awresp_foi],
        [:responder, :full_awresp_foi]
      )
    }
  end

  describe :remove_linked_case do
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

  describe :remove_response do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :std_awdis_foi,]
        )}
  end

  describe :request_amends do
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
