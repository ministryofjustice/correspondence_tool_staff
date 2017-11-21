require 'rails_helper'

RSpec.describe FoiComplianceReview, type: :model do

  let(:compliance_review) { create :foi_compliance_review}

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      Timecop.freeze compliance_review.received_date + 1.day do
        expect(compliance_review).to be_valid
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
        compliance_review.current_state = 'awaiting_responder'
        expect(compliance_review).not_to be_valid
        expect(compliance_review.errors.full_messages).to eq ["Internal reviews must be flagged for clearance"]
      end
    end
  end

  describe 'state_machining' do
    it 'has a state machine' do
      expect(compliance_review.state_machine).to be_a Cases::FOIStateMachine
    end
  end
end
