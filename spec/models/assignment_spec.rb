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

  it 'does not allow other assignment_type values' do
    expect do
      build :assignment, assignment_type: 'badbadbad'
    end.to raise_exception(ArgumentError)
  end


  subject { build(:assignment) }

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
             with(drafter.id, message)
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
      assignment.accept()
      expect(assigned_case).
        to have_received(:responder_assignment_accepted).
             with(drafter.id)
    end

    it 'accepts the assignment' do
      assignment.accept()
      expect(assignment.state).to eq 'accepted'
    end
  end
end
