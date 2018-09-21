require 'rails_helper'

describe 'Overturned ICO FOI cases factory' do

  let(:frozen_time)             { Time.local(2018, 7, 9, 10, 35, 22) }
  let(:disclosure_bmt)          { find_or_create :team_disclosure_bmt }
  let(:manager)                 { disclosure_bmt.users.first }
  let(:responding_team)         { create :responding_team }
  let(:responder)               { responding_team.users.first }
  let(:disclosure_team)         { find_or_create :team_disclosure }
  let(:disclosure_specialist)   { disclosure_team.users.first }


  describe :overturned_ico_foi do
    it 'creates an unassigned ICO Overturned FOI' do
      Timecop.freeze(frozen_time) do
        kase = create :overturned_ico_foi
        expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
        expect(kase.created_at).to eq Time.local(2018, 7, 9, 10, 35, 22)
        expect(kase.ico_reference_number).to match(/^ICOFOIREFNUM\d{3}$/)
        expect(kase.current_state).to eq 'unassigned'
        expect(kase.external_deadline).to eq Date.new(2018, 7, 29)
        expect(kase.internal_deadline).to eq Date.new(2018, 6, 29)
        expect(kase.workflow).to eq 'standard'
        expect(kase.managing_team).to eq disclosure_bmt
        expect(kase.assignments.size).to eq 1

        managing_assignment = kase.assignments.first
        expect(managing_assignment.state).to eq 'accepted'
        expect(managing_assignment.team).to eq disclosure_bmt
        expect(managing_assignment.role).to eq 'managing'

        expect(kase.transitions.size).to eq 0
      end
    end
  end

  describe :awaiting_responder_ot_ico_foi do
    it 'creates an assigned ICO Overturned FOI' do
      Timecop.freeze(frozen_time) do
        kase = create :awaiting_responder_ot_ico_foi, responding_team: responding_team
        expect(kase.current_state).to eq 'awaiting_responder'

        expect(kase.assignments.size).to eq 2
        responding_assignment = kase.assignments.responding.first
        expect(responding_assignment.team).to eq responding_team
        expect(responding_assignment.user).to be_nil
        expect(responding_assignment.state).to eq 'pending'

        expect(kase.transitions.size).to eq 1
        transition = kase.transitions.last
        expect(transition.event).to eq 'assign_responder'
        expect(transition.acting_team_id).to eq disclosure_bmt.id
        expect(transition.target_team_id).to eq responding_team.id
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end
  end

  describe :accepted_ot_ico_foi do
    it 'creates an ICO Overturned FOI in drafting state' do
      kase = create :accepted_ot_ico_foi, responding_team: responding_team, responder: responder
      expect(kase.current_state).to eq 'drafting'
      expect(kase.assignments.size).to eq 2
      responding_assignment = kase.assignments.responding.first
      expect(responding_assignment.team).to eq responding_team
      expect(responding_assignment.user).to eq responder
      expect(responding_assignment.state).to eq 'accepted'

      expect(kase.transitions.size).to eq 2
      transition = kase.transitions.last
      expect(transition.event).to eq 'accept_responder_assignment'
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.target_team_id).to be_nil
      expect(transition.target_user_id).to be_nil
      expect(transition.to_workflow).to be_nil
    end
  end

  describe :with_response_ot_ico_foi do
    it 'creates an ICO Overturned FOI with a response' do
      kase = create :with_response_ot_ico_foi,
                    responding_team: responding_team,
                    responder: responder
      expect(kase.current_state).to eq 'awaiting_dispatch'

      expect(kase.transitions.size).to eq 3
      transition = kase.transitions.last
      expect(transition.event).to eq 'add_responses'
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.target_team_id).to be_nil
      expect(transition.target_user_id).to be_nil
      expect(transition.to_workflow).to be_nil
    end
  end

  describe :responded_ot_ico_foi do
    it 'creates an case in drafting state' do
      kase = create :responded_ot_ico_foi,
                    responding_team: responding_team,
                    responder: responder
      expect(kase.current_state).to eq 'responded'

      expect(kase.transitions.size).to eq 4
      transition = kase.transitions.last
      expect(transition.event).to eq 'respond'
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.target_team_id).to eq responding_team.id
      expect(transition.target_user_id).to eq responder.id
      expect(transition.to_workflow).to be_nil
    end
  end

  describe :closed_ot_ico_foi do
    it 'creates a case in responded state' do
      Timecop.freeze(frozen_time) do
        kase = create :closed_ot_ico_foi,
                      responding_team: responding_team,
                      responder: responder

        expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
        expect(kase.current_state).to eq 'closed'
        expect(kase.assignments.size).to eq 2

        expect(kase.transitions.size).to eq 4
        transition = kase.transitions.last
        expect(transition.event).to eq 'close'
        expect(transition.acting_team_id).to eq responding_team.id
        expect(transition.acting_user_id).to eq responder.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end
  end
end
