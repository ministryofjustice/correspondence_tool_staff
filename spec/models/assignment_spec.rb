require 'rails_helper'

RSpec.describe Assignment, type: :model do

  it { should validate_presence_of(:assignment_type)                 }
  it { should validate_presence_of(:state)                           }
  it { should validate_presence_of(:correspondence)                  }
  it { should validate_presence_of(:assignee)                        }
  it { should validate_presence_of(:assigner)                        }
  it { should belong_to(:correspondence)                             }
  it { should belong_to(:assignee)                                   }
  it { should belong_to(:assigner)                                   }
  it { should have_enum(:state).with_values(['pending', 'rejected', 'accepted']) }
  it { should have_enum(:assignment_type).with_values(['drafter', 'caseworker']) }

  subject { build(:assignment) }

  describe 'callbacks' do
    describe '#update_correspondence' do
      it 'is called after create' do
        expect(subject).to receive(:update_correspondence)
        subject.save
      end

      it 'changes the state of correspondence to awaiting_drafter' do
        expect(subject.correspondence.state).to eq 'submitted'
        subject.save
        expect(subject.correspondence.state).to eq 'awaiting_drafter'
      end
    end
  end

end
