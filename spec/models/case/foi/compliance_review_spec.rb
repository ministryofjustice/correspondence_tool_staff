require 'rails_helper'

RSpec.describe Case::FOI::ComplianceReview, type: :model, parent: :case do

  let(:compliance_review) { create :compliance_review}

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

  describe 'state_machining' do
    it 'has a state machine' do
      expect(compliance_review.state_machine).to be_a Case::FOIStateMachine
    end
  end
  describe 'type' do
    it 'is a type' do
      expect(compliance_review.is_a?(Case::FOI::ComplianceReview)).to be true
    end
  end
end
