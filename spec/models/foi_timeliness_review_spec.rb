require 'rails_helper'

RSpec.describe FoiTimelinessReview, type: :model do

  let(:time_review) { create :foi_timeliness_review}

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      Timecop.freeze time_review.received_date + 1.day do
        expect(time_review).to be_valid
      end
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)            }
    it { should validate_presence_of(:received_date)   }
    it { should validate_presence_of(:subject)         }
    it { should validate_presence_of(:requester_type)  }
    it { should validate_presence_of(:delivery_method) }
    it { should validate_presence_of(:type)            }
  end

  describe 'case_flagged_validation' do
    context 'case is not flagged for clearance' do
      it 'is not valid' do
        time_review.current_state = 'awaiting_responder'
        expect(time_review).not_to be_valid
        expect(time_review.errors.full_messages).to eq ["Internal reviews must be flagged for clearance"]
      end
    end
  end

  describe 'state_machining' do
    it 'has a state machine' do
      expect(time_review.state_machine).to be_a Cases::FOIStateMachine
    end
  end
end
