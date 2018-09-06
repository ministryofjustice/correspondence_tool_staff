require 'rails_helper'

module Workflows
  describe Predicates do
    include PermitPredicate

    before(:all) do
      @team_disclosure                = find_or_create :team_disclosure

      @assigned_responder             = create :responder
      @another_responder              = create :responder
      @disclosure_bmt_user            = find_or_create :disclosure_bmt_user
      @disclosure_specialist          = find_or_create :disclosure_specialist
      @disclosure_specialist_coworker = find_or_create :disclosure_specialist
      @press_officer                  = find_or_create :press_officer

      # Use by the permit_only_these_combinations matcher. Add any new case
      # types (states) that need to be tested here, and unless it's added to
      # the matcher call in the specs below, predicates in the specs below will
      # expected to return false when called with any of the users in
      # all_users().
      #
      # When adding a case type here put them in alphabetical order.
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
        ),
      }
    end

    after(:all) { DbHousekeeping.clean }

    def all_users
      # Users used by the permit_only_these_combinations matcher in combination
      # with all_cases().
      {
        assigned_responder:             @assigned_responder,
        another_responder:              @another_responder,
        disclosure_bmt_user:            @disclosure_bmt_user,
        disclosure_specialist:          @disclosure_specialist,
        disclosure_specialist_coworker: @disclosure_specialist,
        press_officer:                  @press_officer,
      }
    end

    def all_cases
      @all_cases
    end

    describe :responder_is_member_of_assigned_team? do
      it {
        # This matcher will expect the given predicate in the spec description
        # to only allow the combinations of [user, case] provided here. All
        # other combinations of the case types in all_cases() and the user
        # types in all_users() will be expected to fail with this predicate.
        should permit_only_these_combinations(
                 [:assigned_responder, :case_drafting],
                 [:assigned_responder, :case_drafting_flagged],
                 [:assigned_responder, :case_drafting_flagged_press],
                 [:assigned_responder, :case_drafting_trigger],
                 [:assigned_responder, :case_drafting_trigger_press],
               )
      }
    end

    describe :user_is_assigned_responder? do
      it {
        # This matcher will expect the given predicate in the spec description
        # to only allow the combinations of [user, case] provided here. All
        # other combinations of the case types in all_cases() and the user
        # types in all_users() will be expected to fail with this predicate.
        should permit_only_these_combinations(
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
        should permit_only_these_combinations(
                 [:disclosure_specialist,          :case_drafting_flagged],
                 [:disclosure_specialist,          :case_drafting_trigger],
                 [:disclosure_specialist,          :case_unassigned_flagged],
                 [:disclosure_specialist,          :case_unassigned_trigger],
                 [:disclosure_specialist_coworker, :case_drafting_flagged],
                 [:disclosure_specialist_coworker, :case_drafting_trigger],
                 [:disclosure_specialist_coworker, :case_unassigned_flagged],
                 [:disclosure_specialist_coworker, :case_unassigned_trigger],
               ).debug
      end
    end

    describe :case_can_be_unflagged_for_clearance_by_press_officer? do
      it do
        should permit_only_these_combinations(
                 [:press_officer, :case_drafting_flagged_press],
                 [:press_officer, :case_drafting_trigger_press],
                 [:press_officer, :case_unassigned_flagged_press],
                 [:press_officer, :case_unassigned_trigger_press],
               )
      end
    end

    describe :case_is_assigned_to_responder_or_approver_in_same_team_as_current_user do
      it do
        should permit_only_these_combinations(
          [:assigned_responder, :case_drafting],
          [:assigned_responder, :case_drafting_flagged],
          [:assigned_responder, :case_drafting_flagged_press],
          [:assigned_responder, :case_drafting_trigger],
          [:assigned_responder, :case_drafting_trigger_press],
          [:disclosure_specialist, :case_drafting_trigger],
          [:disclosure_specialist, :case_drafting_trigger_press],
          [:disclosure_specialist, :case_unassigned_trigger],
          [:disclosure_specialist, :case_unassigned_trigger_press],
          [:disclosure_specialist_coworker, :case_drafting_trigger],
          [:disclosure_specialist_coworker, :case_drafting_trigger_press],
          [:disclosure_specialist_coworker, :case_unassigned_trigger],
          [:disclosure_specialist_coworker, :case_unassigned_trigger_press],
          [:press_officer, :case_drafting_trigger_press],
          [:press_officer, :case_unassigned_trigger_press]
        )
      end
    end

    describe :can_create_new_overturned_ico? do

      let(:pred)                   { Predicates.new(user: user, kase: kase)  }

      context 'manager' do

        let(:user)          { create :manager }

        context 'SAR ICO appeal' do
          context 'overturned_sars feature set enabled' do
            before(:each) do
              allow(FeatureSet).to receive(:overturned_sars).and_return(double 'Feature', enabled?: true)
            end
            context 'overturned' do
              let(:kase)    { create :closed_ico_sar_case, :overturned_by_ico }
              it 'returns true' do
                expect(pred.can_create_new_overturned_ico?).to be true
              end
            end

            context 'upheld' do
              let(:kase)    { create :closed_ico_sar_case }
              it 'returns false' do
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end
          end

          context 'overturned_sars feature set enabled' do
            before(:each) do
              allow(FeatureSet).to receive(:overturned_sars).and_return(double 'Feature', enabled?: false)
            end
            context 'overturned' do
              let(:kase)    { create :closed_ico_sar_case, :overturned_by_ico }
              it 'returns true' do
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end

            context 'upheld' do
              let(:kase)    { create :closed_ico_sar_case }
              it 'returns false' do
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end
          end
        end

        context 'FO ICO appeal' do
          context 'overturned_fois feature set enabled' do
            before(:each) do
              allow(FeatureSet).to receive(:overturned_fois).and_return(double 'Feature', enabled?: true)
            end
            context 'overturned' do
              let(:kase)    { create :closed_ico_foi_case, :overturned_by_ico }
              it 'returns true' do
                expect(pred.can_create_new_overturned_ico?).to be true
              end
            end

            context 'upheld' do
              let(:kase)    { create :closed_ico_foi_case }
              it 'returns false' do
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end
          end

          context 'overturned_fois feature set enabled' do
            before(:each) do
              allow(FeatureSet).to receive(:overturned_fois).and_return(double 'Feature', enabled?: false)
            end
            context 'overturned' do
              let(:kase)    { create :closed_ico_foi_case, :overturned_by_ico }
              it 'returns true' do
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end

            context 'upheld' do
              let(:kase)    { create :closed_ico_sar_case }
              it 'returns false' do
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end
          end
        end
      end
    end
  end
end
