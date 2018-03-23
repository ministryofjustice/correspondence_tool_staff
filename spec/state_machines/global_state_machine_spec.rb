
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
      should permit_event_to_be_triggered_only_by(
        [:approver, :approving_team, :std_unassigned_foi],
        [:approver, :approving_team, :std_awresp_foi],
        [:approver, :approving_team, :std_draft_foi],
        [:approver, :approving_team, :trig_unassigned_foi],
        [:approver, :approving_team, :trig_awresp_foi],
        [:approver, :approving_team, :trig_draft_foi],
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :full_unassigned_foi],
        [:approver, :approving_team, :full_awresp_foi],
        [:approver, :approving_team, :full_draft_foi],
        [:approver, :approving_team, :full_pdacu_foi],
      )
    }
  end

  describe :accept_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :responding_team, :std_awresp_foi],
        [:responder, :responding_team, :trig_awresp_foi],
        [:responder, :responding_team, :full_awresp_foi]
      )
    }
  end

  describe :add_message_to_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :std_responded_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :trig_pdacu_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :trig_responded_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        [:manager, :managing_team, :full_pdacu_foi],
        [:manager, :managing_team, :full_ppress_foi],
        [:manager, :managing_team, :full_pprivate_foi],
        [:manager, :managing_team, :full_awdis_foi],
        [:manager, :managing_team, :full_responded_foi],

        [:approver, :approving_team, :std_unassigned_foi],
        [:approver, :approving_team, :std_awresp_foi],
        [:approver, :approving_team, :std_draft_foi],
        [:approver, :approving_team, :std_awdis_foi],
        [:approver, :approving_team, :std_responded_foi],
        [:approver, :approving_team, :trig_unassigned_foi],
        [:approver, :approving_team, :trig_awresp_foi],
        [:approver, :approving_team, :trig_draft_foi],
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :trig_awdis_foi],
        [:approver, :approving_team, :trig_responded_foi],
        [:approver, :approving_team, :full_unassigned_foi],
        [:approver, :approving_team, :full_awresp_foi],
        [:approver, :approving_team, :full_draft_foi],
        [:approver, :approving_team, :full_pdacu_foi],
        [:approver, :approving_team, :full_ppress_foi],
        [:approver, :approving_team, :full_pprivate_foi],
        [:approver, :approving_team, :full_awdis_foi],
        [:approver, :approving_team, :full_responded_foi],

        [:responder, :responding_team, :std_unassigned_foi],
        [:responder, :responding_team, :std_awresp_foi],
        [:responder, :responding_team, :std_draft_foi],
        [:responder, :responding_team, :std_awdis_foi],
        [:responder, :responding_team, :std_responded_foi],
        [:responder, :responding_team, :trig_unassigned_foi],
        [:responder, :responding_team, :trig_awresp_foi],
        [:responder, :responding_team, :trig_draft_foi],
        [:responder, :responding_team, :trig_pdacu_foi],
        [:responder, :responding_team, :trig_awdis_foi],
        [:responder, :responding_team, :trig_responded_foi],
        [:responder, :responding_team, :full_unassigned_foi],
        [:responder, :responding_team, :full_awresp_foi],
        [:responder, :responding_team, :full_draft_foi],
        [:responder, :responding_team, :full_pdacu_foi],
        [:responder, :responding_team, :full_ppress_foi],
        [:responder, :responding_team, :full_pprivate_foi],
        [:responder, :responding_team, :full_awdis_foi],
        [:responder, :responding_team, :full_responded_foi])
    }
  end

  describe :add_response_to_flagged_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :responding_team, :trig_draft_foi],
        [:responder, :responding_team, :full_draft_foi]
        )}
  end

  describe :add_responses do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :responding_team, :std_draft_foi],
        [:responder, :responding_team, :std_awdis_foi],
        )}
  end

  describe :approve do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :full_pdacu_foi],
        [:press_officer, :approving_team, :full_ppress_foi],
        [:private_officer, :approving_team, :full_pprivate_foi],
        )}
  end

  describe :approve_and_bypass do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :approving_team, :full_pdacu_foi],
        )}
  end

  describe :assign_responder do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        )}
  end

  describe :assign_to_new_team do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        )}
  end

  describe :close do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :full_awdis_foi],
        )}
  end

  describe :destroy_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :std_responded_foi],
        [:manager, :managing_team, :std_closed_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :trig_pdacu_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :trig_responded_foi],
        [:manager, :managing_team, :trig_closed_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        [:manager, :managing_team, :full_pdacu_foi],
        [:manager, :managing_team, :full_ppress_foi],
        [:manager, :managing_team, :full_pprivate_foi],
        [:manager, :managing_team, :full_awdis_foi],
        [:manager, :managing_team, :full_responded_foi],
        [:manager, :managing_team, :full_closed_foi]
        )}
  end

  describe :edit_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :std_responded_foi],
        [:manager, :managing_team, :std_closed_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :trig_pdacu_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :trig_responded_foi],
        [:manager, :managing_team, :trig_closed_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        [:manager, :managing_team, :full_pdacu_foi],
        [:manager, :managing_team, :full_ppress_foi],
        [:manager, :managing_team, :full_pprivate_foi],
        [:manager, :managing_team, :full_awdis_foi],
        [:manager, :managing_team, :full_responded_foi],
        [:manager, :managing_team, :full_closed_foi]
        )}
  end

  describe :extend_for_pit do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :approving_team, :trig_draft_foi],
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :trig_awdis_foi],
        [:approver, :approving_team, :trig_responded_foi],
        [:approver, :approving_team, :full_draft_foi],
        [:approver, :approving_team, :full_pdacu_foi],
        [:approver, :approving_team, :full_awdis_foi],
        [:approver, :approving_team, :full_responded_foi],
        )}
  end

  describe :flag_for_clearance do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :trig_pdacu_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        [:manager, :managing_team, :full_awdis_foi],

        [:approver, :approving_team, :std_unassigned_foi],
        [:approver, :approving_team, :std_awresp_foi],
        [:approver, :approving_team, :std_draft_foi],
        [:approver, :approving_team, :trig_unassigned_foi],
        [:approver, :approving_team, :trig_awresp_foi],
        [:approver, :approving_team, :trig_draft_foi],
        )}
  end

  describe :link_a_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :std_responded_foi],
        [:manager, :managing_team, :std_closed_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :trig_pdacu_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :trig_responded_foi],
        [:manager, :managing_team, :trig_closed_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        [:manager, :managing_team, :full_pdacu_foi],
        [:manager, :managing_team, :full_ppress_foi],
        [:manager, :managing_team, :full_pprivate_foi],
        [:manager, :managing_team, :full_awdis_foi],
        [:manager, :managing_team, :full_responded_foi],
        [:manager, :managing_team, :full_closed_foi],

        [:approver, :approving_team, :std_unassigned_foi],
        [:approver, :approving_team, :std_awresp_foi],
        [:approver, :approving_team, :std_draft_foi],
        [:approver, :approving_team, :std_awdis_foi],
        [:approver, :approving_team, :std_responded_foi],
        [:approver, :approving_team, :std_closed_foi],
        [:approver, :approving_team, :trig_unassigned_foi],
        [:approver, :approving_team, :trig_awresp_foi],
        [:approver, :approving_team, :trig_draft_foi],
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :trig_awdis_foi],
        [:approver, :approving_team, :trig_responded_foi],
        [:approver, :approving_team, :trig_closed_foi],
        [:approver, :approving_team, :full_unassigned_foi],
        [:approver, :approving_team, :full_awresp_foi],
        [:approver, :approving_team, :full_draft_foi],
        [:approver, :approving_team, :full_pdacu_foi],
        [:approver, :approving_team, :full_ppress_foi],
        [:approver, :approving_team, :full_pprivate_foi],
        [:approver, :approving_team, :full_awdis_foi],
        [:approver, :approving_team, :full_responded_foi],
        [:approver, :approving_team, :full_closed_foi],

        [:another_approver, :approving_team, :std_unassigned_foi],
        [:another_approver, :approving_team, :std_awresp_foi],
        [:another_approver, :approving_team, :std_draft_foi],
        [:another_approver, :approving_team, :std_awdis_foi],
        [:another_approver, :approving_team, :std_responded_foi],
        [:another_approver, :approving_team, :std_closed_foi],
        [:another_approver, :approving_team, :trig_unassigned_foi],
        [:another_approver, :approving_team, :trig_awresp_foi],
        [:another_approver, :approving_team, :trig_draft_foi],
        [:another_approver, :approving_team, :trig_pdacu_foi],
        [:another_approver, :approving_team, :trig_awdis_foi],
        [:another_approver, :approving_team, :trig_responded_foi],
        [:another_approver, :approving_team, :trig_closed_foi],
        [:another_approver, :approving_team, :full_unassigned_foi],
        [:another_approver, :approving_team, :full_awresp_foi],
        [:another_approver, :approving_team, :full_draft_foi],
        [:another_approver, :approving_team, :full_pdacu_foi],
        [:another_approver, :approving_team, :full_ppress_foi],
        [:another_approver, :approving_team, :full_pprivate_foi],
        [:another_approver, :approving_team, :full_awdis_foi],
        [:another_approver, :approving_team, :full_responded_foi],
        [:another_approver, :approving_team, :full_closed_foi],

        [:press_officer, :approving_team, :std_unassigned_foi],
        [:press_officer, :approving_team, :std_awresp_foi],
        [:press_officer, :approving_team, :std_draft_foi],
        [:press_officer, :approving_team, :std_awdis_foi],
        [:press_officer, :approving_team, :std_responded_foi],
        [:press_officer, :approving_team, :std_closed_foi],
        [:press_officer, :approving_team, :trig_unassigned_foi],
        [:press_officer, :approving_team, :trig_awresp_foi],
        [:press_officer, :approving_team, :trig_draft_foi],
        [:press_officer, :approving_team, :trig_pdacu_foi],
        [:press_officer, :approving_team, :trig_awdis_foi],
        [:press_officer, :approving_team, :trig_responded_foi],
        [:press_officer, :approving_team, :trig_closed_foi],
        [:press_officer, :approving_team, :full_unassigned_foi],
        [:press_officer, :approving_team, :full_awresp_foi],
        [:press_officer, :approving_team, :full_draft_foi],
        [:press_officer, :approving_team, :full_pdacu_foi],
        [:press_officer, :approving_team, :full_ppress_foi],
        [:press_officer, :approving_team, :full_pprivate_foi],
        [:press_officer, :approving_team, :full_awdis_foi],
        [:press_officer, :approving_team, :full_responded_foi],
        [:press_officer, :approving_team, :full_closed_foi],

        [:private_officer, :approving_team, :std_unassigned_foi],
        [:private_officer, :approving_team, :std_awresp_foi],
        [:private_officer, :approving_team, :std_draft_foi],
        [:private_officer, :approving_team, :std_awdis_foi],
        [:private_officer, :approving_team, :std_responded_foi],
        [:private_officer, :approving_team, :std_closed_foi],
        [:private_officer, :approving_team, :trig_unassigned_foi],
        [:private_officer, :approving_team, :trig_awresp_foi],
        [:private_officer, :approving_team, :trig_draft_foi],
        [:private_officer, :approving_team, :trig_pdacu_foi],
        [:private_officer, :approving_team, :trig_awdis_foi],
        [:private_officer, :approving_team, :trig_responded_foi],
        [:private_officer, :approving_team, :trig_closed_foi],
        [:private_officer, :approving_team, :full_unassigned_foi],
        [:private_officer, :approving_team, :full_awresp_foi],
        [:private_officer, :approving_team, :full_draft_foi],
        [:private_officer, :approving_team, :full_pdacu_foi],
        [:private_officer, :approving_team, :full_ppress_foi],
        [:private_officer, :approving_team, :full_pprivate_foi],
        [:private_officer, :approving_team, :full_awdis_foi],
        [:private_officer, :approving_team, :full_responded_foi],
        [:private_officer, :approving_team, :full_closed_foi],

        [:responder, :responding_team, :std_unassigned_foi],
        [:responder, :responding_team, :std_awresp_foi],
        [:responder, :responding_team, :std_draft_foi],
        [:responder, :responding_team, :std_awdis_foi],
        [:responder, :responding_team, :std_responded_foi],
        [:responder, :responding_team, :std_closed_foi],
        [:responder, :responding_team, :trig_unassigned_foi],
        [:responder, :responding_team, :trig_awresp_foi],
        [:responder, :responding_team, :trig_draft_foi],
        [:responder, :responding_team, :trig_pdacu_foi],
        [:responder, :responding_team, :trig_awdis_foi],
        [:responder, :responding_team, :trig_responded_foi],
        [:responder, :responding_team, :trig_closed_foi],
        [:responder, :responding_team, :full_unassigned_foi],
        [:responder, :responding_team, :full_awresp_foi],
        [:responder, :responding_team, :full_draft_foi],
        [:responder, :responding_team, :full_pdacu_foi],
        [:responder, :responding_team, :full_ppress_foi],
        [:responder, :responding_team, :full_pprivate_foi],
        [:responder, :responding_team, :full_awdis_foi],
        [:responder, :responding_team, :full_responded_foi],
        [:responder, :responding_team, :full_closed_foi],

        [:another_responder, :responding_team, :std_unassigned_foi],
        [:another_responder, :responding_team, :std_awresp_foi],
        [:another_responder, :responding_team, :std_draft_foi],
        [:another_responder, :responding_team, :std_awdis_foi],
        [:another_responder, :responding_team, :std_responded_foi],
        [:another_responder, :responding_team, :std_closed_foi],
        [:another_responder, :responding_team, :trig_unassigned_foi],
        [:another_responder, :responding_team, :trig_awresp_foi],
        [:another_responder, :responding_team, :trig_draft_foi],
        [:another_responder, :responding_team, :trig_pdacu_foi],
        [:another_responder, :responding_team, :trig_awdis_foi],
        [:another_responder, :responding_team, :trig_responded_foi],
        [:another_responder, :responding_team, :trig_closed_foi],
        [:another_responder, :responding_team, :full_unassigned_foi],
        [:another_responder, :responding_team, :full_awresp_foi],
        [:another_responder, :responding_team, :full_draft_foi],
        [:another_responder, :responding_team, :full_pdacu_foi],
        [:another_responder, :responding_team, :full_ppress_foi],
        [:another_responder, :responding_team, :full_pprivate_foi],
        [:another_responder, :responding_team, :full_awdis_foi],
        [:another_responder, :responding_team, :full_responded_foi],
        [:another_responder, :responding_team, :full_closed_foi])
    }
  end

  describe :reassign_user do
    it {
      should permit_event_to_be_triggered_only_by(
        [:approver, :approving_team, :trig_unassigned_foi],
        [:approver, :approving_team, :trig_awresp_foi],
        [:approver, :approving_team, :trig_draft_foi],
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :trig_awdis_foi],
        [:approver, :approving_team, :trig_responded_foi],
        [:approver, :approving_team, :full_unassigned_foi],
        [:approver, :approving_team, :full_awresp_foi],
        [:approver, :approving_team, :full_draft_foi],
        [:approver, :approving_team, :full_pdacu_foi],
        [:approver, :approving_team, :full_ppress_foi],
        [:approver, :approving_team, :full_pprivate_foi],
        [:approver, :approving_team, :full_awdis_foi],
        [:approver, :approving_team, :full_responded_foi],

        [:responder, :responding_team, :std_draft_foi],
        [:responder, :responding_team, :std_awdis_foi],
        [:responder, :responding_team, :std_responded_foi],
        [:responder, :responding_team, :trig_draft_foi],
        [:responder, :responding_team, :trig_pdacu_foi],
        [:responder, :responding_team, :trig_awdis_foi],
        [:responder, :responding_team, :trig_responded_foi],
        [:responder, :responding_team, :full_draft_foi],
        [:responder, :responding_team, :full_pdacu_foi],
        [:responder, :responding_team, :full_ppress_foi],
        [:responder, :responding_team, :full_pprivate_foi],
        [:responder, :responding_team, :full_awdis_foi],
        [:responder, :responding_team, :full_responded_foi],

        [:press_officier, :press_office, :trig_unassigned_foi],
        [:press_officier, :press_office, :trig_awresp_foi],
        [:press_officier, :press_office, :trig_draft_foi],
        [:press_officier, :press_office, :trig_pdacu_foi],
        [:press_officier, :press_office, :trig_awdis_foi],
        [:press_officier, :press_office, :trig_responded_foi],
        [:press_officier, :press_office, :full_unassigned_foi],
        [:press_officier, :press_office, :full_awresp_foi],
        [:press_officier, :press_office, :full_draft_foi],
        [:press_officier, :press_office, :full_pdacu_foi],
        [:press_officier, :press_office, :full_ppress_foi],
        [:press_officier, :press_office, :full_pprivate_foi],
        [:press_officier, :press_office, :full_awdis_foi],
        [:press_officier, :press_office, :full_responded_foi],

        [:private_officier, :private_office, :trig_unassigned_foi],
        [:private_officier, :private_office, :trig_awresp_foi],
        [:private_officier, :private_office, :trig_draft_foi],
        [:private_officier, :private_office, :trig_pdacu_foi],
        [:private_officier, :private_office, :trig_awdis_foi],
        [:private_officier, :private_office, :trig_responded_foi],
        [:private_officier, :private_office, :full_unassigned_foi],
        [:private_officier, :private_office, :full_awresp_foi],
        [:private_officier, :private_office, :full_draft_foi],
        [:private_officier, :private_office, :full_pdacu_foi],
        [:private_officier, :private_office, :full_ppress_foi],
        [:private_officier, :private_office, :full_pprivate_foi],
        [:private_officier, :private_office, :full_awdis_foi],
        [:private_officier, :private_office, :full_responded_foi],
  )  }
  end

  describe :reject_responder_assignment do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :responding_team, :std_awresp_foi],
        [:responder, :responding_team, :trig_awresp_foi],
        [:responder, :responding_team, :full_awresp_foi]
      )
    }
  end

  describe :remove_linked_case do
    it {
      should permit_event_to_be_triggered_only_by(
        [:manager, :managing_team, :std_unassigned_foi],
        [:manager, :managing_team, :std_awresp_foi],
        [:manager, :managing_team, :std_draft_foi],
        [:manager, :managing_team, :std_awdis_foi],
        [:manager, :managing_team, :std_responded_foi],
        [:manager, :managing_team, :std_closed_foi],
        [:manager, :managing_team, :trig_unassigned_foi],
        [:manager, :managing_team, :trig_awresp_foi],
        [:manager, :managing_team, :trig_draft_foi],
        [:manager, :managing_team, :trig_pdacu_foi],
        [:manager, :managing_team, :trig_awdis_foi],
        [:manager, :managing_team, :trig_responded_foi],
        [:manager, :managing_team, :trig_closed_foi],
        [:manager, :managing_team, :full_unassigned_foi],
        [:manager, :managing_team, :full_awresp_foi],
        [:manager, :managing_team, :full_draft_foi],
        [:manager, :managing_team, :full_pdacu_foi],
        [:manager, :managing_team, :full_ppress_foi],
        [:manager, :managing_team, :full_pprivate_foi],
        [:manager, :managing_team, :full_awdis_foi],
        [:manager, :managing_team, :full_responded_foi],
        [:manager, :managing_team, :full_closed_foi],

        [:approver, :approving_team, :std_unassigned_foi],
        [:approver, :approving_team, :std_awresp_foi],
        [:approver, :approving_team, :std_draft_foi],
        [:approver, :approving_team, :std_awdis_foi],
        [:approver, :approving_team, :std_responded_foi],
        [:approver, :approving_team, :std_closed_foi],
        [:approver, :approving_team, :trig_unassigned_foi],
        [:approver, :approving_team, :trig_awresp_foi],
        [:approver, :approving_team, :trig_draft_foi],
        [:approver, :approving_team, :trig_pdacu_foi],
        [:approver, :approving_team, :trig_awdis_foi],
        [:approver, :approving_team, :trig_responded_foi],
        [:approver, :approving_team, :trig_closed_foi],
        [:approver, :approving_team, :full_unassigned_foi],
        [:approver, :approving_team, :full_awresp_foi],
        [:approver, :approving_team, :full_draft_foi],
        [:approver, :approving_team, :full_pdacu_foi],
        [:approver, :approving_team, :full_ppress_foi],
        [:approver, :approving_team, :full_pprivate_foi],
        [:approver, :approving_team, :full_awdis_foi],
        [:approver, :approving_team, :full_responded_foi],
        [:approver, :approving_team, :full_closed_foi],

        [:another_approver, :approving_team, :std_unassigned_foi],
        [:another_approver, :approving_team, :std_awresp_foi],
        [:another_approver, :approving_team, :std_draft_foi],
        [:another_approver, :approving_team, :std_awdis_foi],
        [:another_approver, :approving_team, :std_responded_foi],
        [:another_approver, :approving_team, :std_closed_foi],
        [:another_approver, :approving_team, :trig_unassigned_foi],
        [:another_approver, :approving_team, :trig_awresp_foi],
        [:another_approver, :approving_team, :trig_draft_foi],
        [:another_approver, :approving_team, :trig_pdacu_foi],
        [:another_approver, :approving_team, :trig_awdis_foi],
        [:another_approver, :approving_team, :trig_responded_foi],
        [:another_approver, :approving_team, :trig_closed_foi],
        [:another_approver, :approving_team, :full_unassigned_foi],
        [:another_approver, :approving_team, :full_awresp_foi],
        [:another_approver, :approving_team, :full_draft_foi],
        [:another_approver, :approving_team, :full_pdacu_foi],
        [:another_approver, :approving_team, :full_ppress_foi],
        [:another_approver, :approving_team, :full_pprivate_foi],
        [:another_approver, :approving_team, :full_awdis_foi],
        [:another_approver, :approving_team, :full_responded_foi],
        [:another_approver, :approving_team, :full_closed_foi],

        [:press_officer, :approving_team, :std_unassigned_foi],
        [:press_officer, :approving_team, :std_awresp_foi],
        [:press_officer, :approving_team, :std_draft_foi],
        [:press_officer, :approving_team, :std_awdis_foi],
        [:press_officer, :approving_team, :std_responded_foi],
        [:press_officer, :approving_team, :std_closed_foi],
        [:press_officer, :approving_team, :trig_unassigned_foi],
        [:press_officer, :approving_team, :trig_awresp_foi],
        [:press_officer, :approving_team, :trig_draft_foi],
        [:press_officer, :approving_team, :trig_pdacu_foi],
        [:press_officer, :approving_team, :trig_awdis_foi],
        [:press_officer, :approving_team, :trig_responded_foi],
        [:press_officer, :approving_team, :trig_closed_foi],
        [:press_officer, :approving_team, :full_unassigned_foi],
        [:press_officer, :approving_team, :full_awresp_foi],
        [:press_officer, :approving_team, :full_draft_foi],
        [:press_officer, :approving_team, :full_pdacu_foi],
        [:press_officer, :approving_team, :full_ppress_foi],
        [:press_officer, :approving_team, :full_pprivate_foi],
        [:press_officer, :approving_team, :full_awdis_foi],
        [:press_officer, :approving_team, :full_responded_foi],
        [:press_officer, :approving_team, :full_closed_foi],

        [:private_officer, :approving_team, :std_unassigned_foi],
        [:private_officer, :approving_team, :std_awresp_foi],
        [:private_officer, :approving_team, :std_draft_foi],
        [:private_officer, :approving_team, :std_awdis_foi],
        [:private_officer, :approving_team, :std_responded_foi],
        [:private_officer, :approving_team, :std_closed_foi],
        [:private_officer, :approving_team, :trig_unassigned_foi],
        [:private_officer, :approving_team, :trig_awresp_foi],
        [:private_officer, :approving_team, :trig_draft_foi],
        [:private_officer, :approving_team, :trig_pdacu_foi],
        [:private_officer, :approving_team, :trig_awdis_foi],
        [:private_officer, :approving_team, :trig_responded_foi],
        [:private_officer, :approving_team, :trig_closed_foi],
        [:private_officer, :approving_team, :full_unassigned_foi],
        [:private_officer, :approving_team, :full_awresp_foi],
        [:private_officer, :approving_team, :full_draft_foi],
        [:private_officer, :approving_team, :full_pdacu_foi],
        [:private_officer, :approving_team, :full_ppress_foi],
        [:private_officer, :approving_team, :full_pprivate_foi],
        [:private_officer, :approving_team, :full_awdis_foi],
        [:private_officer, :approving_team, :full_responded_foi],
        [:private_officer, :approving_team, :full_closed_foi],

        [:responder, :responding_team, :std_unassigned_foi],
        [:responder, :responding_team, :std_awresp_foi],
        [:responder, :responding_team, :std_draft_foi],
        [:responder, :responding_team, :std_awdis_foi],
        [:responder, :responding_team, :std_responded_foi],
        [:responder, :responding_team, :std_closed_foi],
        [:responder, :responding_team, :trig_unassigned_foi],
        [:responder, :responding_team, :trig_awresp_foi],
        [:responder, :responding_team, :trig_draft_foi],
        [:responder, :responding_team, :trig_pdacu_foi],
        [:responder, :responding_team, :trig_awdis_foi],
        [:responder, :responding_team, :trig_responded_foi],
        [:responder, :responding_team, :trig_closed_foi],
        [:responder, :responding_team, :full_unassigned_foi],
        [:responder, :responding_team, :full_awresp_foi],
        [:responder, :responding_team, :full_draft_foi],
        [:responder, :responding_team, :full_pdacu_foi],
        [:responder, :responding_team, :full_ppress_foi],
        [:responder, :responding_team, :full_pprivate_foi],
        [:responder, :responding_team, :full_awdis_foi],
        [:responder, :responding_team, :full_responded_foi],
        [:responder, :responding_team, :full_closed_foi],

        [:another_responder, :responding_team, :std_unassigned_foi],
        [:another_responder, :responding_team, :std_awresp_foi],
        [:another_responder, :responding_team, :std_draft_foi],
        [:another_responder, :responding_team, :std_awdis_foi],
        [:another_responder, :responding_team, :std_responded_foi],
        [:another_responder, :responding_team, :std_closed_foi],
        [:another_responder, :responding_team, :trig_unassigned_foi],
        [:another_responder, :responding_team, :trig_awresp_foi],
        [:another_responder, :responding_team, :trig_draft_foi],
        [:another_responder, :responding_team, :trig_pdacu_foi],
        [:another_responder, :responding_team, :trig_awdis_foi],
        [:another_responder, :responding_team, :trig_responded_foi],
        [:another_responder, :responding_team, :trig_closed_foi],
        [:another_responder, :responding_team, :full_unassigned_foi],
        [:another_responder, :responding_team, :full_awresp_foi],
        [:another_responder, :responding_team, :full_draft_foi],
        [:another_responder, :responding_team, :full_pdacu_foi],
        [:another_responder, :responding_team, :full_ppress_foi],
        [:another_responder, :responding_team, :full_pprivate_foi],
        [:another_responder, :responding_team, :full_awdis_foi],
        [:another_responder, :responding_team, :full_responded_foi],
        [:another_responder, :responding_team, :full_closed_foi])
    }
  end

  describe :remove_response do
    it {
      should permit_event_to_be_triggered_only_by(
        [:responder, :responding_team, :std_awdis_foi,]
        )}
  end

  describe :request_amends do
    it {
      should permit_event_to_be_triggered_only_by(
        [:press_officer, :press_office, :full_ppress_foi],
        [:private_officer, :private_office, :full_pprivate_foi]
      )}

  def all_users
    @setup.users
  end

  def all_teams
    @setup.teams
  end

  def all_cases
    @setup.cases
  end

end
