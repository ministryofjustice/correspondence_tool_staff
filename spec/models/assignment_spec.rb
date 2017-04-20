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
#

require 'rails_helper'

RSpec.describe Assignment, type: :model do
  let(:assigned_case)   { create :assigned_case }
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
                .with_values(%w{pending accepted rejected}) }
  it { should have_enum(:role)
                .with_values(%w{managing responding approving}) }

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
end
