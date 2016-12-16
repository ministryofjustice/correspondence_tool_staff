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
  it { should have_enum(:state).with_values(['pending', 'rejected', 'accepted']) }
  it { should have_enum(:assignment_type).with_values(['drafter', 'caseworker']) }

  subject { build(:assignment) }

  describe 'callbacks' do
    describe '#update_case' do
      it 'is called after create' do
        expect(subject).to receive(:update_case)
        subject.save
      end

      it 'changes the state of case to awaiting_drafter' do
        expect(subject.case.state).to eq 'submitted'
        subject.save
        expect(subject.case.state).to eq 'awaiting_drafter'
      end
    end
  end

end
