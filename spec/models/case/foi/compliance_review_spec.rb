# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe Case::FOI::ComplianceReview, type: :model, parent: :case do

  let(:compliance_review) { build_stubbed :compliance_review}

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
    it { should validate_presence_of(:requester_type)  }
    it { should validate_presence_of(:delivery_method) }
    it { should validate_presence_of(:type)            }
  end

  describe 'state_machining' do
    context 'drafting state' do
      it 'has an FOI state machine' do
        allow(compliance_review).to receive(:current_state).and_return('drafting')
        expect(compliance_review.state_machine).to be_a ConfigurableStateMachine::Machine
      end
    end

    context 'unassigned state' do
      it 'has a Configurable State machine' do
        allow(compliance_review).to receive(:current_state).and_return('unassigned')
        expect(compliance_review.state_machine).to be_a ConfigurableStateMachine::Machine
      end
    end
  end
  describe 'type' do
    it 'is a type' do
      expect(compliance_review.is_a?(Case::FOI::ComplianceReview)).to be true
    end
  end
end
