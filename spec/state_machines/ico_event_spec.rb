require 'rails_helper'

describe 'state machine' do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  context 'usual suspects' do
    before(:all) do
      DbHousekeeping.clean
      @setup = StandardSetup.new(
        only_cases: [
          :ico_foi_unassigned,
          :ico_foi_awaiting_responder,
          :ico_foi_accepted,
          :ico_foi_pending_dacu,
          :ico_foi_awaiting_dispatch,
          :ico_foi_responded,
          :ico_foi_closed,
          :ico_sar_unassigned,
          :ico_sar_awaiting_responder,
          :ico_sar_accepted,
          :ico_sar_pending_dacu,
          :ico_sar_awaiting_dispatch,
          :ico_sar_responded,
          :ico_sar_closed,
        ]
      )

    end

    after(:all) { DbHousekeeping.clean }

    describe 'setup' do
      context 'FOI' do
        context 'trigger workflow' do
          context 'awaiting dispatch' do
            it 'is trigger workflow' do
              kase = @setup.ico_foi_awaiting_dispatch
              expect(kase.current_state).to eq 'awaiting_dispatch'
              expect(kase.workflow).to eq 'trigger'
              expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq 'accepted'
              expect(kase.approver_assignments.for_team(@setup.press_office_team)).to be_empty
              expect(kase.approver_assignments.for_team(@setup.private_office_team)).to be_empty
            end
          end

          context 'awaiting dispatch' do
            it 'is trigger workflow' do
              kase = @setup.ico_sar_awaiting_dispatch
              expect(kase.current_state).to eq 'awaiting_dispatch'
              expect(kase.workflow).to eq 'trigger'
              expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq 'accepted'
              expect(kase.approver_assignments.for_team(@setup.press_office_team)).to be_empty
              expect(kase.approver_assignments.for_team(@setup.private_office_team)).to be_empty
            end
          end

          context 'pending dacu clearance' do
            it 'is trigger workflow' do
              kase = @setup.ico_foi_pending_dacu
              expect(kase.current_state).to eq 'pending_dacu_clearance'
              expect(kase.workflow).to eq 'trigger'
              expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq 'accepted'
              expect(kase.approver_assignments.for_team(@setup.press_office_team)).to be_empty
              expect(kase.approver_assignments.for_team(@setup.private_office_team)).to be_empty
            end
          end
        end
      end
    end


    describe :accept_approver_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_specialist, :ico_foi_unassigned],
          [:disclosure_specialist, :ico_foi_awaiting_responder],
          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_sar_unassigned],
          [:disclosure_specialist, :ico_sar_awaiting_responder],
          [:disclosure_specialist, :ico_sar_accepted],

          [:disclosure_specialist_coworker, :ico_foi_unassigned],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_sar_unassigned],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_sar_accepted],

               )
      }
    end

    describe :accept_responder_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
          [:responder, :ico_foi_awaiting_responder],
          [:responder, :ico_sar_awaiting_responder],
          [:another_responder_in_same_team, :ico_foi_awaiting_responder],
          [:another_responder_in_same_team, :ico_sar_awaiting_responder]
               )
      }
    end

    describe :add_message_to_case do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_pending_dacu],
          [:disclosure_bmt, :ico_foi_awaiting_dispatch],
          [:disclosure_bmt, :ico_foi_responded],
          [:disclosure_bmt, :ico_foi_closed],

          [:disclosure_bmt, :ico_sar_unassigned],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_pending_dacu],
          [:disclosure_bmt, :ico_sar_awaiting_dispatch],
          [:disclosure_bmt, :ico_sar_responded],
          [:disclosure_bmt, :ico_sar_closed],

          [:responder, :ico_foi_awaiting_responder],
          [:responder, :ico_foi_accepted],
          [:responder, :ico_foi_pending_dacu],
          [:responder, :ico_foi_awaiting_dispatch],
          [:responder, :ico_foi_responded],
          [:responder, :ico_foi_closed],

          [:responder, :ico_sar_awaiting_responder],
          [:responder, :ico_sar_accepted],
          [:responder, :ico_sar_pending_dacu],
          [:responder, :ico_sar_awaiting_dispatch],
          [:responder, :ico_sar_responded],
          [:responder, :ico_sar_closed],

          [:another_responder_in_same_team, :ico_foi_awaiting_responder],
          [:another_responder_in_same_team, :ico_foi_accepted],
          [:another_responder_in_same_team, :ico_foi_pending_dacu],
          [:another_responder_in_same_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_foi_responded],
          [:another_responder_in_same_team, :ico_foi_closed],

          [:another_responder_in_same_team, :ico_sar_awaiting_responder],
          [:another_responder_in_same_team, :ico_sar_accepted],
          [:another_responder_in_same_team, :ico_sar_pending_dacu],
          [:another_responder_in_same_team, :ico_sar_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_sar_responded],
          [:another_responder_in_same_team, :ico_sar_closed],

          [:disclosure_specialist, :ico_foi_unassigned],
          [:disclosure_specialist, :ico_foi_awaiting_responder],
          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_foi_responded],
          [:disclosure_specialist, :ico_foi_closed],

          [:disclosure_specialist, :ico_sar_unassigned],
          [:disclosure_specialist, :ico_sar_awaiting_responder],
          [:disclosure_specialist, :ico_sar_accepted],
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_responded],
          [:disclosure_specialist, :ico_sar_closed],

          [:disclosure_specialist_coworker, :ico_foi_unassigned],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_foi_pending_dacu],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_foi_responded],
          [:disclosure_specialist_coworker, :ico_foi_closed],

          [:disclosure_specialist_coworker, :ico_sar_unassigned],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_sar_accepted],
          [:disclosure_specialist_coworker, :ico_sar_pending_dacu],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_responded],
          [:disclosure_specialist_coworker, :ico_sar_closed],
               )
      }
    end

    describe :approve do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_sar_pending_dacu],
               )}
    end

    describe :assign_responder do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_sar_unassigned],
               )}
    end

    describe :assign_to_new_team do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_closed],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_closed],
        )}
    end

    describe :close do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_responded],
          [:disclosure_bmt, :ico_sar_responded],
        )}
    end

    describe :destroy_case do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_pending_dacu],
          [:disclosure_bmt, :ico_foi_awaiting_dispatch],
          [:disclosure_bmt, :ico_foi_responded],
          [:disclosure_bmt, :ico_foi_closed],
          [:disclosure_bmt, :ico_sar_unassigned],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_pending_dacu],
          [:disclosure_bmt, :ico_sar_awaiting_dispatch],
          [:disclosure_bmt, :ico_sar_responded],
          [:disclosure_bmt, :ico_sar_closed],

               )}
    end

    describe :edit_case do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_pending_dacu],
          [:disclosure_bmt, :ico_foi_awaiting_dispatch],
          [:disclosure_bmt, :ico_foi_responded],
          [:disclosure_bmt, :ico_foi_closed],
          [:disclosure_bmt, :ico_sar_unassigned],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_pending_dacu],
          [:disclosure_bmt, :ico_sar_awaiting_dispatch],
          [:disclosure_bmt, :ico_sar_responded],
          [:disclosure_bmt, :ico_sar_closed],

               )}
    end

    describe :flag_for_clearance do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_sar_unassigned],
        )}
    end

    describe :link_a_case do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_pending_dacu],
          [:disclosure_bmt, :ico_foi_awaiting_dispatch],
          [:disclosure_bmt, :ico_foi_responded],
          [:disclosure_bmt, :ico_foi_closed],

          [:disclosure_bmt, :ico_sar_unassigned],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_pending_dacu],
          [:disclosure_bmt, :ico_sar_awaiting_dispatch],
          [:disclosure_bmt, :ico_sar_responded],
          [:disclosure_bmt, :ico_sar_closed],


          [:responder, :ico_foi_unassigned],
          [:responder, :ico_foi_awaiting_responder],
          [:responder, :ico_foi_accepted],
          [:responder, :ico_foi_pending_dacu],
          [:responder, :ico_foi_awaiting_dispatch],
          [:responder, :ico_foi_responded],
          [:responder, :ico_foi_closed],

          [:responder, :ico_sar_unassigned],
          [:responder, :ico_sar_awaiting_responder],
          [:responder, :ico_sar_accepted],
          [:responder, :ico_sar_pending_dacu],
          [:responder, :ico_sar_awaiting_dispatch],
          [:responder, :ico_sar_responded],
          [:responder, :ico_sar_closed],


          [:another_responder_in_same_team, :ico_foi_unassigned],
          [:another_responder_in_same_team, :ico_foi_awaiting_responder],
          [:another_responder_in_same_team, :ico_foi_accepted],
          [:another_responder_in_same_team, :ico_foi_pending_dacu],
          [:another_responder_in_same_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_foi_responded],
          [:another_responder_in_same_team, :ico_foi_closed],

          [:another_responder_in_same_team, :ico_sar_unassigned],
          [:another_responder_in_same_team, :ico_sar_awaiting_responder],
          [:another_responder_in_same_team, :ico_sar_accepted],
          [:another_responder_in_same_team, :ico_sar_pending_dacu],
          [:another_responder_in_same_team, :ico_sar_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_sar_responded],
          [:another_responder_in_same_team, :ico_sar_closed],

          [:disclosure_specialist, :ico_foi_unassigned],
          [:disclosure_specialist, :ico_foi_awaiting_responder],
          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_foi_responded],
          [:disclosure_specialist, :ico_foi_closed],

          [:disclosure_specialist, :ico_sar_unassigned],
          [:disclosure_specialist, :ico_sar_awaiting_responder],
          [:disclosure_specialist, :ico_sar_accepted],
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_responded],
          [:disclosure_specialist, :ico_sar_closed],

          [:disclosure_specialist_coworker, :ico_foi_unassigned],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_foi_pending_dacu],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_foi_responded],
          [:disclosure_specialist_coworker, :ico_foi_closed],

          [:disclosure_specialist_coworker, :ico_sar_unassigned],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_sar_accepted],
          [:disclosure_specialist_coworker, :ico_sar_pending_dacu],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_responded],
          [:disclosure_specialist_coworker, :ico_sar_closed],

          [:another_disclosure_specialist, :ico_foi_unassigned],
          [:another_disclosure_specialist, :ico_foi_awaiting_responder],
          [:another_disclosure_specialist, :ico_foi_accepted],
          [:another_disclosure_specialist, :ico_foi_pending_dacu],
          [:another_disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:another_disclosure_specialist, :ico_foi_responded],
          [:another_disclosure_specialist, :ico_foi_closed],

          [:another_disclosure_specialist, :ico_sar_unassigned],
          [:another_disclosure_specialist, :ico_sar_awaiting_responder],
          [:another_disclosure_specialist, :ico_sar_accepted],
          [:another_disclosure_specialist, :ico_sar_pending_dacu],
          [:another_disclosure_specialist, :ico_sar_awaiting_dispatch],
          [:another_disclosure_specialist, :ico_sar_responded],
          [:another_disclosure_specialist, :ico_sar_closed],


          [:another_responder_in_diff_team, :ico_foi_unassigned],
          [:another_responder_in_diff_team, :ico_foi_awaiting_responder],
          [:another_responder_in_diff_team, :ico_foi_accepted],
          [:another_responder_in_diff_team, :ico_foi_pending_dacu],
          [:another_responder_in_diff_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_diff_team, :ico_foi_responded],
          [:another_responder_in_diff_team, :ico_foi_closed],

          [:another_responder_in_diff_team, :ico_sar_unassigned],
          [:another_responder_in_diff_team, :ico_sar_awaiting_responder],
          [:another_responder_in_diff_team, :ico_sar_accepted],
          [:another_responder_in_diff_team, :ico_sar_pending_dacu],
          [:another_responder_in_diff_team, :ico_sar_awaiting_dispatch],
          [:another_responder_in_diff_team, :ico_sar_responded],
          [:another_responder_in_diff_team, :ico_sar_closed],

          [:private_officer, :ico_foi_unassigned],
          [:private_officer, :ico_foi_awaiting_responder],
          [:private_officer, :ico_foi_accepted],
          [:private_officer, :ico_foi_pending_dacu],
          [:private_officer, :ico_foi_awaiting_dispatch],
          [:private_officer, :ico_foi_responded],
          [:private_officer, :ico_foi_closed],

          [:private_officer, :ico_sar_unassigned],
          [:private_officer, :ico_sar_awaiting_responder],
          [:private_officer, :ico_sar_accepted],
          [:private_officer, :ico_sar_pending_dacu],
          [:private_officer, :ico_sar_awaiting_dispatch],
          [:private_officer, :ico_sar_responded],
          [:private_officer, :ico_sar_closed],

          [:press_officer, :ico_foi_unassigned],
          [:press_officer, :ico_foi_awaiting_responder],
          [:press_officer, :ico_foi_accepted],
          [:press_officer, :ico_foi_pending_dacu],
          [:press_officer, :ico_foi_awaiting_dispatch],
          [:press_officer, :ico_foi_responded],
          [:press_officer, :ico_foi_closed],

          [:press_officer, :ico_sar_unassigned],
          [:press_officer, :ico_sar_awaiting_responder],
          [:press_officer, :ico_sar_accepted],
          [:press_officer, :ico_sar_pending_dacu],
          [:press_officer, :ico_sar_awaiting_dispatch],
          [:press_officer, :ico_sar_responded],
          [:press_officer, :ico_sar_closed]

               )
      }
    end

    describe :reassign_user do
      it {
        should permit_event_to_be_triggered_only_by(
          [:responder, :ico_foi_accepted],
          [:responder, :ico_sar_accepted],
          [:responder, :ico_foi_pending_dacu],
          [:responder, :ico_sar_pending_dacu],
          [:responder, :ico_foi_awaiting_dispatch],
          [:responder, :ico_sar_awaiting_dispatch],

          [:another_responder_in_same_team, :ico_foi_accepted],
          [:another_responder_in_same_team, :ico_sar_accepted],
          [:another_responder_in_same_team, :ico_foi_pending_dacu],
          [:another_responder_in_same_team, :ico_sar_pending_dacu],
          [:another_responder_in_same_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_sar_awaiting_dispatch],

          [:disclosure_specialist, :ico_foi_unassigned],
          [:disclosure_specialist, :ico_foi_awaiting_responder],
          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_unassigned],
          [:disclosure_specialist, :ico_sar_awaiting_responder],
          [:disclosure_specialist, :ico_sar_accepted],
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],

          [:disclosure_specialist_coworker, :ico_foi_unassigned],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_foi_pending_dacu],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_unassigned],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_sar_accepted],
          [:disclosure_specialist_coworker, :ico_sar_pending_dacu],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],
               )  }
    end

    describe :reject_responder_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
          [:responder, :ico_foi_awaiting_responder],
          [:responder, :ico_sar_awaiting_responder],
          [:another_responder_in_same_team, :ico_foi_awaiting_responder],
          [:another_responder_in_same_team, :ico_sar_awaiting_responder]
               )
      }
    end

    describe :remove_linked_case do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_pending_dacu],
          [:disclosure_bmt, :ico_foi_awaiting_dispatch],
          [:disclosure_bmt, :ico_foi_responded],
          [:disclosure_bmt, :ico_foi_closed],

          [:disclosure_bmt, :ico_sar_unassigned],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_pending_dacu],
          [:disclosure_bmt, :ico_sar_awaiting_dispatch],
          [:disclosure_bmt, :ico_sar_responded],
          [:disclosure_bmt, :ico_sar_closed],


          [:responder, :ico_foi_unassigned],
          [:responder, :ico_foi_awaiting_responder],
          [:responder, :ico_foi_accepted],
          [:responder, :ico_foi_pending_dacu],
          [:responder, :ico_foi_awaiting_dispatch],
          [:responder, :ico_foi_responded],
          [:responder, :ico_foi_closed],

          [:responder, :ico_sar_unassigned],
          [:responder, :ico_sar_awaiting_responder],
          [:responder, :ico_sar_accepted],
          [:responder, :ico_sar_pending_dacu],
          [:responder, :ico_sar_awaiting_dispatch],
          [:responder, :ico_sar_responded],
          [:responder, :ico_sar_closed],


          [:another_responder_in_same_team, :ico_foi_unassigned],
          [:another_responder_in_same_team, :ico_foi_awaiting_responder],
          [:another_responder_in_same_team, :ico_foi_accepted],
          [:another_responder_in_same_team, :ico_foi_pending_dacu],
          [:another_responder_in_same_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_foi_responded],
          [:another_responder_in_same_team, :ico_foi_closed],

          [:another_responder_in_same_team, :ico_sar_unassigned],
          [:another_responder_in_same_team, :ico_sar_awaiting_responder],
          [:another_responder_in_same_team, :ico_sar_accepted],
          [:another_responder_in_same_team, :ico_sar_pending_dacu],
          [:another_responder_in_same_team, :ico_sar_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_sar_responded],
          [:another_responder_in_same_team, :ico_sar_closed],

          [:disclosure_specialist, :ico_foi_unassigned],
          [:disclosure_specialist, :ico_foi_awaiting_responder],
          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_foi_responded],
          [:disclosure_specialist, :ico_foi_closed],

          [:disclosure_specialist, :ico_sar_unassigned],
          [:disclosure_specialist, :ico_sar_awaiting_responder],
          [:disclosure_specialist, :ico_sar_accepted],
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_responded],
          [:disclosure_specialist, :ico_sar_closed],

          [:disclosure_specialist_coworker, :ico_foi_unassigned],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_foi_pending_dacu],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_foi_responded],
          [:disclosure_specialist_coworker, :ico_foi_closed],

          [:disclosure_specialist_coworker, :ico_sar_unassigned],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_sar_accepted],
          [:disclosure_specialist_coworker, :ico_sar_pending_dacu],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_responded],
          [:disclosure_specialist_coworker, :ico_sar_closed],

          [:another_disclosure_specialist, :ico_foi_unassigned],
          [:another_disclosure_specialist, :ico_foi_awaiting_responder],
          [:another_disclosure_specialist, :ico_foi_accepted],
          [:another_disclosure_specialist, :ico_foi_pending_dacu],
          [:another_disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:another_disclosure_specialist, :ico_foi_responded],
          [:another_disclosure_specialist, :ico_foi_closed],

          [:another_disclosure_specialist, :ico_sar_unassigned],
          [:another_disclosure_specialist, :ico_sar_awaiting_responder],
          [:another_disclosure_specialist, :ico_sar_accepted],
          [:another_disclosure_specialist, :ico_sar_pending_dacu],
          [:another_disclosure_specialist, :ico_sar_awaiting_dispatch],
          [:another_disclosure_specialist, :ico_sar_responded],
          [:another_disclosure_specialist, :ico_sar_closed],


          [:another_responder_in_diff_team, :ico_foi_unassigned],
          [:another_responder_in_diff_team, :ico_foi_awaiting_responder],
          [:another_responder_in_diff_team, :ico_foi_accepted],
          [:another_responder_in_diff_team, :ico_foi_pending_dacu],
          [:another_responder_in_diff_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_diff_team, :ico_foi_responded],
          [:another_responder_in_diff_team, :ico_foi_closed],

          [:another_responder_in_diff_team, :ico_sar_unassigned],
          [:another_responder_in_diff_team, :ico_sar_awaiting_responder],
          [:another_responder_in_diff_team, :ico_sar_accepted],
          [:another_responder_in_diff_team, :ico_sar_pending_dacu],
          [:another_responder_in_diff_team, :ico_sar_awaiting_dispatch],
          [:another_responder_in_diff_team, :ico_sar_responded],
          [:another_responder_in_diff_team, :ico_sar_closed],

          [:private_officer, :ico_foi_unassigned],
          [:private_officer, :ico_foi_awaiting_responder],
          [:private_officer, :ico_foi_accepted],
          [:private_officer, :ico_foi_pending_dacu],
          [:private_officer, :ico_foi_awaiting_dispatch],
          [:private_officer, :ico_foi_responded],
          [:private_officer, :ico_foi_closed],

          [:private_officer, :ico_sar_unassigned],
          [:private_officer, :ico_sar_awaiting_responder],
          [:private_officer, :ico_sar_accepted],
          [:private_officer, :ico_sar_pending_dacu],
          [:private_officer, :ico_sar_awaiting_dispatch],
          [:private_officer, :ico_sar_responded],
          [:private_officer, :ico_sar_closed],

          [:press_officer, :ico_foi_unassigned],
          [:press_officer, :ico_foi_awaiting_responder],
          [:press_officer, :ico_foi_accepted],
          [:press_officer, :ico_foi_pending_dacu],
          [:press_officer, :ico_foi_awaiting_dispatch],
          [:press_officer, :ico_foi_responded],
          [:press_officer, :ico_foi_closed],

          [:press_officer, :ico_sar_unassigned],
          [:press_officer, :ico_sar_awaiting_responder],
          [:press_officer, :ico_sar_accepted],
          [:press_officer, :ico_sar_pending_dacu],
          [:press_officer, :ico_sar_awaiting_dispatch],
          [:press_officer, :ico_sar_responded],
          [:press_officer, :ico_sar_closed]
   )    }
    end

    describe :respond do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],

          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],
        )}
    end

    describe :unaccept_approver_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_sar_pending_dacu],
        )}
    end

    describe :upload_response_and_approve do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_sar_pending_dacu],

               )
      }
    end

    describe :upload_response_and_return_for_redraft do
      it {
        should permit_event_to_be_triggered_only_by(
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_sar_pending_dacu],
               )
      }
    end

  ############## EMAIL TESTS ################


    describe :add_message_to_case do
      it {
        should have_after_hook(
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_foi_pending_dacu],
          [:disclosure_bmt, :ico_foi_awaiting_dispatch],
          [:disclosure_bmt, :ico_foi_responded],

          [:disclosure_bmt, :ico_sar_accepted],
          [:disclosure_bmt, :ico_sar_pending_dacu],
          [:disclosure_bmt, :ico_sar_awaiting_dispatch],
          [:disclosure_bmt, :ico_sar_responded],

          [:responder, :ico_foi_accepted],
          [:responder, :ico_foi_pending_dacu],
          [:responder, :ico_foi_awaiting_dispatch],
          [:responder, :ico_foi_responded],

          [:responder, :ico_sar_accepted],
          [:responder, :ico_sar_pending_dacu],
          [:responder, :ico_sar_awaiting_dispatch],
          [:responder, :ico_sar_responded],

          [:another_responder_in_same_team, :ico_foi_accepted],
          [:another_responder_in_same_team, :ico_foi_pending_dacu],
          [:another_responder_in_same_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_foi_responded],

          [:another_responder_in_same_team, :ico_sar_accepted],
          [:another_responder_in_same_team, :ico_sar_pending_dacu],
          [:another_responder_in_same_team, :ico_sar_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_sar_responded],

          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_foi_responded],

          [:disclosure_specialist, :ico_sar_accepted],
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_responded],

          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_foi_pending_dacu],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_foi_responded],

          [:disclosure_specialist_coworker, :ico_sar_accepted],
          [:disclosure_specialist_coworker, :ico_sar_pending_dacu],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_responded],

       ).with_hook('Workflows::Hooks', :notify_responder_message_received)
      }
    end

    describe :approve do
      it {
        should have_after_hook(
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_foi_pending_dacu],

       ).with_hook('Workflows::Hooks', :notify_responder_ready_to_send)
      }
    end

    describe :assign_responder do
      it {
        should have_after_hook(
          [:disclosure_bmt, :ico_foi_unassigned],
          [:disclosure_bmt, :ico_sar_unassigned],
       ).with_hook('Workflows::Hooks', :assign_responder_email)
      }
    end


    describe :assign_to_new_team do
      it {
        should have_after_hook(
          [:disclosure_bmt, :ico_foi_awaiting_responder],
          [:disclosure_bmt, :ico_foi_accepted],
          [:disclosure_bmt, :ico_sar_awaiting_responder],
          [:disclosure_bmt, :ico_sar_accepted],
       ).with_hook('Workflows::Hooks', :assign_responder_email)
      }
    end


    describe :reassign_user do
      it {
        should have_after_hook(
          [:responder, :ico_foi_accepted],
          [:responder, :ico_sar_accepted],
          [:responder, :ico_foi_pending_dacu],
          [:responder, :ico_sar_pending_dacu],
          [:responder, :ico_foi_awaiting_dispatch],
          [:responder, :ico_sar_awaiting_dispatch],

          [:another_responder_in_same_team, :ico_foi_accepted],
          [:another_responder_in_same_team, :ico_sar_accepted],
          [:another_responder_in_same_team, :ico_foi_pending_dacu],
          [:another_responder_in_same_team, :ico_sar_pending_dacu],
          [:another_responder_in_same_team, :ico_foi_awaiting_dispatch],
          [:another_responder_in_same_team, :ico_sar_awaiting_dispatch],

          [:disclosure_specialist, :ico_foi_unassigned],
          [:disclosure_specialist, :ico_foi_awaiting_responder],
          [:disclosure_specialist, :ico_foi_accepted],
          [:disclosure_specialist, :ico_foi_pending_dacu],
          [:disclosure_specialist, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist, :ico_sar_unassigned],
          [:disclosure_specialist, :ico_sar_awaiting_responder],
          [:disclosure_specialist, :ico_sar_accepted],
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_sar_awaiting_dispatch],

          [:disclosure_specialist_coworker, :ico_foi_unassigned],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_foi_accepted],
          [:disclosure_specialist_coworker, :ico_foi_pending_dacu],
          [:disclosure_specialist_coworker, :ico_foi_awaiting_dispatch],
          [:disclosure_specialist_coworker, :ico_sar_unassigned],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_responder],
          [:disclosure_specialist_coworker, :ico_sar_accepted],
          [:disclosure_specialist_coworker, :ico_sar_pending_dacu],
          [:disclosure_specialist_coworker, :ico_sar_awaiting_dispatch],

       ).with_hook('Workflows::Hooks', :reassign_user_email)
      }
    end

    describe :upload_response_and_return_for_redraft do
      it {
        should have_after_hook(
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_foi_pending_dacu],

       ).with_hook('Workflows::Hooks', :notify_responder_redraft_requested)
      }
    end

    describe :upload_response_and_approve do
      it {
        should have_after_hook(
          [:disclosure_specialist, :ico_sar_pending_dacu],
          [:disclosure_specialist, :ico_foi_pending_dacu],

       ).with_hook('Workflows::Hooks', :notify_responder_ready_to_send)
      }
    end
  end
end
