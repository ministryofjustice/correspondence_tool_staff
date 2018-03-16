require 'rails_helper'

module Workflows
  describe Predicates do
    include PermitPredicate

    before(:all) do
      @team_disclosure            = find_or_create :team_disclosure

      @assigned_responder         = create :responder
      @another_responder          = create :responder
      @disclosure_bmt_user        = find_or_create :disclosure_bmt_user
      @disclosure_specialist      = find_or_create :disclosure_specialist
      @press_officer              = find_or_create :press_officer

      @all_cases = {
        case_drafting: create(
          :case_being_drafted,
          responder: @assigned_responder
        ),
        case_drafting_flagged: create(
          :case_being_drafted,
          :flagged,
          approving_team: @team_disclosure,
          responder: @assigned_responder
        ),
        case_drafting_flagged_press: create(
          :case_being_drafted,
          :flagged,
          :press_office,
          approver: @press_officer,
          responder: @assigned_responder
        ),
        case_drafting_trigger: create(
          :case_being_drafted,
          :flagged_accepted,
          approver: @disclosure_specialist,
          approving_team: @team_disclosure,
          responder: @assigned_responder
        ),
        case_drafting_trigger_press: create(
          :case_being_drafted,
          :flagged_accepted,
          :press_office,
          approver: @press_officer,
          disclosure_specialist: @disclosure_specialist,
          responder: @assigned_responder
        ),
        case_unassigned: create(
          :case
        ),
        case_unassigned_flagged: create(
          :case,
          :flagged,
          :dacu_disclosure
        ),
        case_unassigned_flagged_press: create(
          :case,
          :flagged,
          :press_office,
          approver: @press_officer,
          responder: @assigned_responder
        ),
        case_unassigned_trigger: create(
          :case,
          :flagged_accepted,
          :dacu_disclosure
        ),
        case_unassigned_trigger_press: create(
          :case,
          :flagged_accepted,
          :press_office,
          approver: @press_officer,
          disclosure_specialist: @disclosure_specialist,
          responder: @assigned_responder
        ),
      }
    end

    def all_users
      {
        assigned_responder:    @assigned_responder,
        another_responder:     @another_responder,
        disclosure_bmt_user:   @disclosure_bmt_user,
        disclosure_specialist: @disclosure_specialist,
        press_officer:         @press_officer,
      }
    end

    def all_cases
      @all_cases
    end

    describe :responder_is_member_of_assigned_team? do
      it {
        should permit(
                 [:assigned_responder, :case_drafting],
                 [:assigned_responder, :case_drafting_flagged],
                 [:assigned_responder, :case_drafting_flagged_press],
                 [:assigned_responder, :case_drafting_trigger],
                 [:assigned_responder, :case_drafting_trigger_press],
               )
      }
    end

    describe :case_can_be_unflagged_for_clearance_by_disclosure_specialist? do
      it do
        should permit(
                 [:disclosure_specialist, :case_drafting_flagged],
                 [:disclosure_specialist, :case_drafting_trigger],
                 [:disclosure_specialist, :case_unassigned_flagged],
                 [:disclosure_specialist, :case_unassigned_trigger],
               )
      end
    end

    describe :case_can_be_unflagged_for_clearance_by_press_officer? do
      it do
        should permit(
                 [:press_officer, :case_drafting_flagged_press],
                 [:press_officer, :case_drafting_trigger_press],
                 [:press_officer, :case_unassigned_flagged_press],
                 [:press_officer, :case_unassigned_trigger_press],
               )
      end
    end
  end
end
