require 'rails_helper'

module Workflows
  describe Predicates do
    include PermitPredicate

    before(:all) do
      @team_disclosure                = find_or_create :team_disclosure
      @foi_responding_team            = find_or_create :foi_responding_team
      @assigned_responder             = find_or_create :foi_responder
      @another_responder              = create :responder

      @disclosure_bmt_user            = find_or_create :disclosure_bmt_user
      @disclosure_specialist          = find_or_create :disclosure_specialist
      @disclosure_specialist_coworker = create :approver,
                                               approving_team: @team_disclosure
      @press_officer                  = find_or_create :press_officer

      # Use by the permit_only_these_combinations matcher. Add any new case
      # types (states) that need to be tested here, and unless it's added to
      # the matcher call in the specs below, predicates in the specs below will
      # expected to return false when called with any of the users in
      # all_users().
      #
      # When adding a case type here put them in alphabetical order.
      @all_cases = {
        case_drafting:                 create(:case_being_drafted),
        case_drafting_flagged:         create(:case_being_drafted, :flagged),
        case_drafting_flagged_press:   create(:case_being_drafted,
                                              :flagged,
                                              :press_office),
        case_drafting_trigger:         create(:case_being_drafted,
                                              :flagged_accepted),
        case_drafting_trigger_press:   create(:case_being_drafted,
                                              :flagged_accepted,
                                              :press_office),
        case_unassigned:               create(:case),
        case_unassigned_flagged:       create(:case, :flagged),
        case_unassigned_flagged_press: create(:case, :full_approval, :flagged),
        case_unassigned_trigger:       create(:case, :flagged_accepted),
        case_unassigned_trigger_press: create(:case,
                                              :flagged_accepted,
                                              :full_approval),
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
               )
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
          [:press_officer, :case_drafting_flagged_press],
          [:press_officer, :case_unassigned_trigger_press],
          [:press_officer, :case_unassigned_flagged_press],
        )
      end
    end

    describe :can_create_new_overturned_ico? do

      let(:pred)                   { Predicates.new(user: user, kase: kase)  }

      context 'manager' do

        let(:user)          { create :manager }

        context 'SAR ICO appeal' do
          context 'overturned' do
            let(:kase)    { create :closed_ico_sar_case, :overturned_by_ico }

            context 'overturn already exists' do
              it 'returns true' do
                expect(kase).to receive(:lacks_overturn?).and_return(false)
                expect(pred.can_create_new_overturned_ico?).to be false
              end
            end

            context 'no overturn exists yet' do
              it 'returns true' do
                expect(kase).to receive(:lacks_overturn?).and_return(true)
                expect(pred.can_create_new_overturned_ico?).to be true
              end
            end
          end

          context 'upheld' do
            let(:kase)    { create :closed_ico_sar_case }
            it 'returns false' do
              expect(pred.can_create_new_overturned_ico?).to be false
            end
          end
        end

        context 'FOI ICO appeal' do
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
      end
    end

    describe :assigned_team_member_and_case_outside_escalation_period? do
      let(:kase)        { @all_cases[:case_drafting] }
      let(:predicate)   { Predicates.new(user: user, kase: kase) }

      context 'manager' do
        let(:user)    { @disclosure_bmt_user }
        it 'returns false' do
          expect(predicate.assigned_team_member_and_case_outside_escalation_period?).to be false
        end
      end

      context 'approver' do
        let(:user)      { @disclosure_specialist }
        it 'returns false' do
          expect(predicate.assigned_team_member_and_case_outside_escalation_period?).to be false
        end
      end

      context 'responder' do
        let(:user)        { @assigned_responder }
        context 'in same team' do
          context 'within escalation deadline' do
            it 'returns false' do
              allow(kase).to receive(:escalation_deadline).and_return(2.days.from_now)
              expect(predicate.assigned_team_member_and_case_outside_escalation_period?).to be false
            end
          end
          context 'outside escalation deadline' do
            it 'returns true' do
              allow(kase).to receive(:escalation_deadline).and_return(2.days.ago)
              expect(predicate.assigned_team_member_and_case_outside_escalation_period?).to be true
            end
          end
        end

        context 'in different team' do
          let(:user)      { @another_responder }
          it 'returns false' do
            expect(predicate.assigned_team_member_and_case_outside_escalation_period?).to be false
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
