# == Schema Information
#
# Table name: case_transitions
#
#  id          :integer          not null, primary key
#  event       :string
#  to_state    :string           not null
#  metadata    :jsonb
#  sort_key    :integer          not null
#  case_id     :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#

require 'rails_helper'

RSpec.describe CaseTransition, type: :model do
  let(:kase) { create(:case) }
  let(:managing_team)   { create :managing_team }
  let(:responding_team) { create :responding_team }
  let(:approving_team)  { create :approving_team }
  let(:assign_responder_transition) do
    create :case_transition_assign_responder,
           case_id: kase.id,
           managing_team: managing_team,
           responding_team: responding_team
  end
  let(:flag_case_for_clearance_transition) do
    create :flag_case_for_clearance_transition,
           case_id: kase.id,
           managing_team: managing_team,
           approving_team: approving_team
  end

  it 'has a user association' do
    expect(assign_responder_transition.user)
      .to eq User.find(assign_responder_transition.user_id)
  end

  it 'has a managing_team' do
    expect(assign_responder_transition.managing_team_id)
      .to eq managing_team.id
  end

  it 'has a responding_team' do
    bu = assign_responder_transition.responding_team
    expect(bu).to eq Team.find(bu.id)
  end

  it 'has an approving_team' do
    expect(flag_case_for_clearance_transition.approving_team)
      .to eq approving_team
  end

  describe 'after_destroy' do
    let(:case_assigned) do
      create(
        :case_transition_assign_responder,
        case_id: kase.id
      )
    end

    let(:assignment_accepted) do
      create(
        :case_transition_accept_responder_assignment,
        case_id: kase.id
      )
    end

    before do
      kase
      case_assigned
      assignment_accepted
    end

    it 'updates most_recent' do
      expect(case_assigned.reload.most_recent).to eq false
      expect(assignment_accepted.reload.most_recent).to eq true
      assignment_accepted.destroy
      expect(case_assigned.reload.most_recent).to eq true
    end
  end

  describe 'responded scope' do
    let!(:responded_transition) do
      create :case_transition_respond, case_id: kase.id
    end
    let!(:add_responses_transition) do
      create :case_transition_add_responses, case_id: kase.id
    end

    it 'limits scope to "responded" transitions' do
      expect(CaseTransition.all.count).to eq 2
      expect(CaseTransition.all.responded.count).to eq 1
      expect(CaseTransition.all.responded.last).to eq responded_transition
    end
  end

  describe 'messages scope' do
    it 'only returns messages for the case' do
      kase = create :pending_dacu_clearance_case
      responder = kase.responder
      team = kase.responding_team
      approver = kase.approvers.first

      kase.state_machine.add_message_to_case! responder, team, 'Message #1 - from responder'
      kase.state_machine.add_message_to_case! approver, team,  'Message #2 - from approver'
      kase.state_machine.add_message_to_case! responder, team,  'Message #3 - from responder'

      expect(kase.transitions.messages.size).to eq 3
      expect(kase.transitions.size > 3).to be true
      expect(kase.transitions.messages.map(&:message)).to eq(
        [
          'Message #1 - from responder',
          'Message #2 - from approver',
          'Message #3 - from responder'
        ])

    end
  end

  describe 'message validation' do
    it 'errors if not present' do
      kase = create :accepted_case
      transition = CaseTransition.new(
                                   case_id: kase.id,
                                   event: 'add_message_to_case',
                                   user_id: kase.responder.id,
                                   messaging_team_id: kase.responding_team.id
      )
      expect(transition).not_to be_valid
      expect(transition.errors[:message]).to eq ["can't be blank"]

    end
  end
end
