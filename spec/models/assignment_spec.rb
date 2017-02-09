# == Schema Information
#
# Table name: assignments
#
#  id              :integer          not null, primary key
#  assignment_type :enum
#  state           :enum             default("pending")
#  case_id         :integer
#  assignee_id     :integer
#  assigner_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'rails_helper'

RSpec.describe Assignment, type: :model do

  subject { build(:drafter_assignment) }

  it { should validate_presence_of(:assignment_type) }
  it { should validate_presence_of(:state)           }
  it { should validate_presence_of(:case)            }
  it { should validate_presence_of(:assignee)        }
  it { should validate_presence_of(:assigner)        }
  it { should belong_to(:case)                       }
  it { should belong_to(:assignee)                   }
  it { should belong_to(:assigner)                   }
  it { should have_enum(:state).with_values(['pending', 'accepted', 'rejected']) }
  it { should have_enum(:assignment_type).with_values(['drafter', 'caseworker']) }

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

  it 'does not allow other assignment_type values' do
    expect do
      build :assignment, assignment_type: 'badbadbad'
    end.to raise_exception(ArgumentError)
  end

  describe '#reject' do
    let(:assigned_case) { create :assigned_case }
    let(:state_machine) { assigned_case.state_machine }
    let(:assignment)    { assigned_case.assignments.detect(&:drafter?) }
    let(:drafter)       { assignment.assignee }
    let(:message)       { |example| "test #{example.description}" }

    before do
      allow(assigned_case).to receive(:responder_assignment_rejected)
    end

    it 'triggers the case event' do
      assignment.reject(message)
      expect(assigned_case).
        to have_received(:responder_assignment_rejected).
             with(drafter.id, message, assignment.id)
    end

    it 'deletes the assignment' do
      assignment.reject(message)
      expect(Assignment.find_by(id: assignment.id)).to be_nil
    end
  end

  describe '#accept' do
    let(:assigned_case) { create :assigned_case }
    let(:state_machine) { assigned_case.state_machine }
    let(:assignment)    { assigned_case.assignments.detect(&:drafter?) }
    let(:drafter)       { assignment.assignee }
    let(:message)       { |example| "test #{example.description}" }

    before do
      allow(assigned_case).to receive(:responder_assignment_accepted)
    end

    it 'triggers the case event' do
      assignment.accept
      expect(assigned_case).
        to have_received(:responder_assignment_accepted).
             with(drafter.id)
    end

    it 'accepts the assignment' do
      assignment.accept
      expect(assignment.state).to eq 'accepted'
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
