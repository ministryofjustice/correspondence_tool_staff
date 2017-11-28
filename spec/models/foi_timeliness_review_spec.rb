require 'rails_helper'

RSpec.describe FOITimelinessReview, type: :model, parent: :case do

  let(:time_review) { create :FOI_timeliness_review}

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

  describe 'state_machining' do
    it 'has a state machine' do
      expect(time_review.state_machine).to be_a Cases::FOIStateMachine
    end
  end
end
