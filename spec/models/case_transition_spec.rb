# == Schema Information
#
# Table name: case_transitions
#
#  id             :integer          not null, primary key
#  event          :string
#  to_state       :string           not null
#  metadata       :jsonb
#  sort_key       :integer          not null
#  case_id        :integer          not null
#  most_recent    :boolean          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  acting_user_id :integer
#  acting_team_id :integer
#  target_user_id :integer
#  target_team_id :integer
#  to_workflow    :string
#

require "rails_helper"

RSpec.describe CaseTransition, type: :model do
  let(:kase) { create(:case) }
  let(:managing_team)   { create :managing_team }
  let(:responding_team) { create :responding_team }
  let(:approving_team)  { create :approving_team }
  let(:assign_responder_transition) do
    create :case_transition_assign_responder,
           case_id: kase.id,
           acting_team: managing_team,
           target_team: responding_team
  end
  let(:flag_case_for_clearance_transition) do
    create :flag_case_for_clearance_transition,
           case_id: kase.id,
           acting_team: managing_team,
           target_team: approving_team
  end

  it "has a acting_team_id" do
    expect(assign_responder_transition.acting_team_id)
      .to eq managing_team.id
  end

  it "has an approving_team" do
    expect(flag_case_for_clearance_transition.target_team_id)
      .to eq approving_team.id
  end

  describe "after_destroy" do
    let(:case_assigned) do
      create(
        :case_transition_assign_responder,
        case_id: kase.id,
      )
    end

    let(:assignment_accepted) do
      create(
        :case_transition_accept_responder_assignment,
        case_id: kase.id,
      )
    end

    before do
      kase
      case_assigned
      assignment_accepted
    end

    it "updates most_recent" do
      expect(case_assigned.reload.most_recent).to eq false
      expect(assignment_accepted.reload.most_recent).to eq true
      assignment_accepted.destroy!
      expect(case_assigned.reload.most_recent).to eq true
    end
  end

  describe "responded scope" do
    let!(:responded_transition) do
      create :case_transition_respond, case_id: kase.id
    end

    before do
      create :case_transition_add_responses, case_id: kase.id
    end

    it 'limits scope to "responded" transitions' do
      expect(described_class.all.count).to eq 5
      expect(described_class.all.responded.count).to eq 1
      expect(described_class.all.responded.last).to eq responded_transition
    end
  end

  describe "further_clearance scope" do
    let!(:further_clearance_transition) do
      create :case_transition_further_clearance, case_id: kase.id
    end

    before do
      create :case_transition_add_responses, case_id: kase.id
    end

    it 'limits scope to "further_clearance" transitions' do
      expect(described_class.all.count).to eq 5
      expect(described_class.all.further_clearance.count).to eq 1
      expect(described_class.all.further_clearance.last).to eq further_clearance_transition
    end
  end

  describe "case_history scope" do
    it "does not return any add messages entries" do
      kase = create :accepted_case
      responder = kase.responder
      team = kase.responding_team

      kase.state_machine.add_message_to_case! acting_user: responder, acting_team: team, message: "Message #1 - from responder"

      expect(kase.transitions.case_history.map(&:event))
          .not_to include(%w[add_message_to_case])
    end

    it "does not return any flagged/unflagged entries" do
      kase = create :case, :flagged

      create :unflag_case_for_clearance_transition, case: kase

      expect(kase.transitions.case_history.map(&:event))
          .not_to include(%w[flag_for_clearance unflag_for_clearance])
    end
  end

  describe "messages scope" do
    it "only returns messages for the case" do
      kase = create :pending_dacu_clearance_case
      responder = kase.responder
      team = kase.responding_team
      approver = kase.approvers.first
      approver_team = kase.approving_teams.first

      kase.state_machine.add_message_to_case! acting_user: responder, acting_team: team, message: "Message #1 - from responder"
      kase.state_machine.add_message_to_case! acting_user: approver,  acting_team: approver_team, message: "Message #2 - from approver"
      kase.state_machine.add_message_to_case! acting_user: responder, acting_team: team, message: "Message #3 - from responder"

      expect(kase.transitions.messages.size).to eq 3
      expect(kase.transitions.size > 3).to be true
      expect(kase.transitions.messages.map(&:message)).to eq(
        [
          "Message #1 - from responder",
          "Message #2 - from approver",
          "Message #3 - from responder",
        ],
      )
    end
  end

  describe "message validation" do
    it "errors if not present" do
      kase = create :accepted_case
      transition = described_class.new(
        case_id: kase.id,
        acting_user: kase.responder,
        acting_team: kase.responding_team,
      )

      %w[
        add_message_to_case
        add_note_to_case
        annotate_retention_changes
        annotate_system_retention_changes
      ].each do |event|
        transition.event = event

        expect(transition).not_to be_valid
        expect(transition.errors.added?(:message, :blank)).to eq(true)
      end
    end
  end
end
