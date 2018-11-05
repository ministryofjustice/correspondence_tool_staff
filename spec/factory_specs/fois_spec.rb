require "rails_helper"

require 'rails_helper'

describe 'FOI cases factory' do
  let(:frozen_time)           { Time.local(2018, 7, 9, 10, 35, 22) }
  let(:team_disclosure_bmt)   { find_or_create :team_disclosure_bmt }
  let(:manager)               { team_disclosure_bmt.managers.first }
  let(:foi_responding_team)   { create :foi_responding_team }
  let(:foi_responder)         { foi_responding_team.responders.first }
  let(:team_disclosure)       { find_or_create :team_disclosure }
  let(:disclosure_specialist) { team_disclosure.approvers.first }
  let(:press_office)          { find_or_create :team_press_office }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_office)        { find_or_create :team_private_office }
  let(:private_officer)       { find_or_create :private_officer }

  let(:managing_assignment) do
    kase.assignments.managing.first
  end

  let(:disclosure_assignment) do
    kase.assignments.approving.detect do |assignment|
      assignment.team == team_disclosure
    end
  end

  let(:press_office_assignment) do
    kase.assignments.approving.detect do |assignment|
      assignment.team == press_office
    end
  end

  let(:private_office_assignment) do
    kase.assignments.approving.detect do |assignment|
      assignment.team == private_office
    end
  end

  let(:responding_assignment) do
    kase.assignments.responding.first
  end

  let(:flag_for_disclosure_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'flag_for_clearance' &&
        transition.target_team == team_disclosure
    end
  end

  let(:assign_foi_responder_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'assign_responder' &&
        transition.target_team == foi_responding_team
    end
  end

  let(:accept_approver_user_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'accept_approver_user' &&
        transition.target_team == team_disclosure
    end
  end

  let(:accept_responder_assignment_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'accept_responder_assignment' &&
        transition.acting_team == foi_responding_team
    end
  end

  let(:take_on_for_disclosure_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'take_on_for_approval' &&
        transition.target_team == team_disclosure
    end
  end

  let(:take_on_for_press_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'take_on_for_approval' &&
        transition.target_team == press_office
    end
  end

  let(:take_on_for_private_transition) do
    kase.transitions.detect do |transition|
      transition.event == 'take_on_for_approval' &&
        transition.target_team == private_office
    end
  end

  describe 'foi_case' do
    let(:kase) { create :foi_case }

    it 'creates an unassigned standard FOI case' do
      Timecop.freeze(frozen_time) do
        expect(kase).to be_instance_of(Case::FOI::Standard)
        expect(kase.workflow).to eq 'standard'
        expect(kase.current_state).to eq 'unassigned'
        expect(kase.external_deadline).to eq Date.new(2018, 8, 6)
        expect(kase.internal_deadline).to eq Date.new(2018, 7, 23)
        expect(kase.managing_team).to eq team_disclosure_bmt
        expect(kase.created_at).to eq 4.business_days.before(frozen_time)

        expect(kase.assignments.size).to eq 1
        expect(managing_assignment.state).to eq 'accepted'
        expect(managing_assignment.team).to eq team_disclosure_bmt

        expect(kase.transitions.size).to eq 0
      end
    end

    context 'flagged' do
      let(:kase) { create :foi_case, :flagged }

      it 'flags the case' do
        expect(kase.workflow).to eq 'trigger'

        expect(kase.assignments.size).to eq 2
        expect(managing_assignment.state).to eq 'accepted'
        expect(managing_assignment.team).to eq team_disclosure_bmt
        expect(managing_assignment.role).to eq 'managing'
        expect(disclosure_assignment).not_to be_nil
        expect(disclosure_assignment.state).to eq 'pending'
        expect(disclosure_assignment.user_id).to be_nil

        expect(kase.transitions.size).to eq 1
        expect(flag_for_disclosure_transition).to be_present
      end
    end
  end

  describe 'awaiting_responder_case' do
    let(:kase) { create :awaiting_responder_case }

    it 'creates a standard FOI case awaiting responder acceptance' do
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.workflow).to eq 'standard'
      expect(kase.current_state).to eq 'awaiting_responder'

      expect(kase.assignments.size).to eq 2
      expect(responding_assignment.state).to eq 'pending'
      expect(responding_assignment.team).to eq foi_responding_team
      expect(responding_assignment.user).to be_nil

      expect(kase.transitions.size).to eq 1
      expect(assign_foi_responder_transition).to be_present
    end

    context 'flagged_accepted' do
      let(:kase) { create :awaiting_responder_case, :flagged_accepted }

      it 'creates a trigger FOI case that has been accepted' do
        expect(kase.workflow).to eq 'trigger'
        expect(kase.current_state).to eq 'awaiting_responder'

        expect(kase.assignments.size).to eq 3
        expect(disclosure_assignment.state).to eq 'accepted'

        expect(kase.transitions.size).to eq 3
        expect(flag_for_disclosure_transition).to be_present
        expect(accept_approver_user_transition).to be_present
        expect(accept_approver_user_transition.target_user)
          .to eq disclosure_specialist
      end

    end

    context 'taken_on_by_disclosure' do
      let(:kase) { create :awaiting_responder_case, :taken_on_by_disclosure }

      it 'creates a FOI case that has been taken on by disclosure' do
        expect(kase.workflow).to eq 'trigger'
        expect(kase.current_state).to eq 'awaiting_responder'

        expect(kase.assignments.size).to eq 3
        expect(disclosure_assignment.state).to eq 'accepted'

        expect(kase.transitions.size).to eq 2
        expect(take_on_for_disclosure_transition).to be_present
      end
    end
  end

  describe 'case_being_drafted' do
    let(:kase) { create :accepted_case }

    it 'creates a standard FOI case that has been accepted by the responder' do
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.workflow).to eq 'standard'
      expect(kase.current_state).to eq 'drafting'

      expect(kase.assignments.size).to eq 2
      expect(responding_assignment.state).to eq 'accepted'
      expect(responding_assignment.team).to eq foi_responding_team
      expect(responding_assignment.user).to eq foi_responder

      expect(kase.transitions.size).to eq 2
      expect(accept_responder_assignment_transition).to be_present
      expect(accept_responder_assignment_transition.acting_user)
        .to eq foi_responder
    end

    context 'taken_on_by_press' do
      let(:kase) { create :accepted_case, :taken_on_by_press }

      it 'creates a full approval FOI case taken on by press office' do
        expect(kase.workflow).to eq 'full_approval'

        expect(kase.assignments.size).to eq 5
        expect(disclosure_assignment.state).to eq 'accepted'
        expect(disclosure_assignment.user).to eq disclosure_specialist
        expect(press_office_assignment.state).to eq 'accepted'
        expect(press_office_assignment.user).to eq press_officer
        expect(private_office_assignment.state).to eq 'accepted'
        expect(private_office_assignment.user).to eq private_officer

        expect(kase.transitions.size).to eq 5
        expect(take_on_for_disclosure_transition).to be_present
        expect(take_on_for_disclosure_transition.target_user).to eq disclosure_specialist
        expect(take_on_for_disclosure_transition.acting_team).to eq press_office
        expect(take_on_for_disclosure_transition.acting_user).to eq press_officer
        expect(take_on_for_press_transition).to be_present
        expect(take_on_for_press_transition.target_user).to eq press_officer
        expect(take_on_for_press_transition.acting_team).to eq press_office
        expect(take_on_for_press_transition.acting_user).to eq press_officer
        expect(take_on_for_private_transition).to be_present
        expect(take_on_for_private_transition.target_user).to eq private_officer
        expect(take_on_for_private_transition.acting_team).to eq press_office
        expect(take_on_for_private_transition.acting_user).to eq press_officer
      end

      it 'takes the case on in drafting' do
        expect(kase.transitions.map { |t| [t.event, t.target_team&.name] })
          .to match_array [
                ['assign_responder', 'FOI Responding Team'],
                ['accept_responder_assignment', nil],
                ['take_on_for_approval', 'Disclosure'],
                ['take_on_for_approval', 'Press Office'],
                ['take_on_for_approval', 'Private Office'],
              ]
      end

      context 'and flagged' do
        let(:kase) { create :accepted_case,
                            :flagged,
                            :taken_on_by_press }

        it 'takes the case on as disclosure for the disclosure assignment' do
          expect(kase.workflow).to eq 'full_approval'

          expect(kase.assignments.size).to eq 5
          expect(disclosure_assignment.state).to eq 'pending'
          expect(press_office_assignment).to be_present
          expect(private_office_assignment).to be_present

          expect(kase.transitions.size).to eq 5
          expect(flag_for_disclosure_transition).to be_present
          expect(flag_for_disclosure_transition.acting_team).to eq team_disclosure_bmt
          expect(flag_for_disclosure_transition.acting_user).to eq manager
          expect(take_on_for_press_transition.acting_team).to eq press_office
          expect(take_on_for_private_transition.acting_team).to eq press_office
        end
      end

      context 'and taken_on_by_disclosure' do
        let(:kase) { create :accepted_case,
                            :taken_on_by_disclosure,
                            :taken_on_by_press }

        it 'takes the case on as disclosure for the disclosure assignment' do
          expect(kase.workflow).to eq 'full_approval'

          expect(kase.assignments.size).to eq 5
          expect(disclosure_assignment.state).to eq 'accepted'
          expect(disclosure_assignment.user).to eq disclosure_specialist
          expect(press_office_assignment).to be_present
          expect(private_office_assignment).to be_present

          expect(kase.transitions.size).to eq 5
          expect(take_on_for_disclosure_transition).to be_present
          expect(take_on_for_disclosure_transition.target_user).to eq disclosure_specialist
          expect(take_on_for_disclosure_transition.acting_team).to eq team_disclosure
          expect(take_on_for_disclosure_transition.acting_user).to eq disclosure_specialist
          expect(take_on_for_press_transition.acting_team).to eq press_office
          expect(take_on_for_private_transition.acting_team).to eq press_office
        end
      end

      context 'in awaiting_responder state' do
        let(:kase) { create :accepted_case,
                            taken_on_by_press: 'awaiting_responder' }

        it 'takes the case on in the correct state' do
          expect(kase.transitions.map { |t| [t.event, t.target_team&.name] })
            .to match_array [
                  ['assign_responder', 'FOI Responding Team'],
                  ['take_on_for_approval', 'Disclosure'],
                  ['take_on_for_approval', 'Press Office'],
                  ['take_on_for_approval', 'Private Office'],
                  ['accept_responder_assignment', nil],
                ]
        end
      end
    end
  end
end
