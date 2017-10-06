# == Schema Information
#
# Table name: assignments
#
#  id         :integer          not null, primary key
#  state      :enum             default("pending")
#  case_id    :integer          not null
#  team_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role       :enum
#  user_id    :integer
#  approved   :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe Assignment, type: :model do
  let(:assigned_case)   { create :assigned_case }
  let(:assigned_flagged_case) { create :assigned_case, :flagged }
  let(:responded_trigger_case) { create :responded_case, :flagged_accepted }
  let(:approved_trigger_case) { create :approved_case }
  let(:state_machine)   { assigned_case.state_machine }
  let(:assignment)      { assigned_case.responder_assignment }
  let(:responder)       { responding_team.responders.first }
  let(:responding_team) { assignment.team }

  subject { build(:assignment) }

  it { should validate_presence_of(:state)    }
  it { should validate_presence_of(:case)     }
  it { should validate_presence_of(:team)     }
  it { should belong_to(:case)                }
  it { should belong_to(:team)                }
  it { should belong_to(:user)                }
  it { should have_enum(:state)
                .with_values(%w{pending accepted bypassed rejected}) }
  it { should have_enum(:role)
                .with_values(%w{managing responding approving}) }

  describe 'scope approved' do
    it 'returns assignments that have been approved' do
      assigned_flagged_case
      responded_trigger_case
      approved_trigger_case
      expect(Assignment.approved)
        .to match_array approved_trigger_case.approver_assignments
    end
  end

  describe 'scope unapproved' do
    it 'returns assignments that have not been approved' do
      assigned_flagged_case
      responded_trigger_case
      approved_trigger_case
      expect(Assignment.unapproved)
        .to match_array assigned_flagged_case.assignments +
                        responded_trigger_case.assignments +
                        [approved_trigger_case.responder_assignment,
                         approved_trigger_case.managing_assignment]
    end
  end

  describe 'scope for_user' do
    it 'returns the assignments for a given user' do
      expect(
        approved_trigger_case.assignments
          .for_user(approved_trigger_case.approvers.first)
      ).to match_array approved_trigger_case.approver_assignments
    end
  end

  describe 'scope with_teams' do
    it 'returns assignments that have not been rejected by the given teams' do
      expect(
        approved_trigger_case.assignments
          .with_teams(approved_trigger_case.approving_teams)
      ).to match_array approved_trigger_case.approver_assignments
    end
  end

  describe 'scope last_responding' do
    it 'returns the last responding assignment' do
      create :assignment, :responding
      assignment2 = create :assignment, :responding
      expect(Assignment.last_responding).to eq [assignment2]
    end
  end

  describe '#reasons_for_rejection' do
    it 'is required for rejection' do
      expect(Assignment.new(state: 'rejected')).
        to validate_presence_of(:reasons_for_rejection)
    end

    it 'is not required for acceptance' do
      expect(Assignment.new(state: 'accepted')).
        not_to validate_presence_of(:reasons_for_rejection)
    end

    it 'is not required for the default state' do
      expect(Assignment.new).
        not_to validate_presence_of(:reasons_for_rejection)
    end
  end

  describe '#reject' do
    let(:message) { |example| "test #{example.description}" }

    before do
      allow(assignment.case).to receive(:responder_assignment_rejected)
    end

    it 'triggers the case event' do
      assignment.reject(responder, message)
      expect(assignment.case).
        to have_received(:responder_assignment_rejected).
             with(responder, responding_team, message)
    end

    it 'changes the state to rejected' do
      assignment.reject(responder, message)
      expect(assignment.state).to eq 'rejected'
    end
  end

  describe '#accept' do
    before do
      allow(assignment.case).to receive(:responder_assignment_accepted)
    end

    it 'triggers the case event' do
      assignment.accept(responder)
      expect(assignment.case).
        to have_received(:responder_assignment_accepted).
             with(responder, responding_team)
    end

    it 'accepts the assignment' do
      assignment.accept(responder)
      expect(assignment.state).to eq 'accepted'
    end

    it 'assigns the user' do
      assignment.accept(responder)
      expect(assignment.user).to eq responder
    end
  end

  describe '#assign_and_validate_state' do
    it 'assigns state to the assignment in memory' do
      subject.save
      expect(subject.state).to eq 'pending'
      subject.assign_and_validate_state('accepted')
      expect(subject.state).to eq 'accepted'
      expect(subject.reload.state).to eq 'pending'
    end

    it 'triggers validation' do
      allow(subject).to receive(:valid?)
      subject.assign_and_validate_state(:accepted)
      expect(subject).to have_received(:valid?)
    end
  end

  context 'approved validation' do
    context 'approving roles' do
      it 'is valid when true' do
        assignment =  create :approved_assignment
        expect(assignment.approved?).to be true
        expect(assignment).to be_valid
      end

      it 'is valid when false' do
        assignment = create :approver_assignment
        expect(assignment.approved?).to be false
        expect(assignment).to be_valid
      end
    end

    context 'non-approving_role' do
      it 'is valid when false' do
        assignment =  create :assignment
        expect(assignment.approved?).to be false
        expect(assignment).to be_valid
      end

      it 'is invalid when true' do
        assignment =  create :assignment
        assignment.approved = true
        expect(assignment.approved?).to be true
        expect(assignment).not_to be_valid
        expect(assignment.errors[:approved]).to eq ['true']
      end
    end
  end
end
