require 'rails_helper'

describe ComplaintCaseUpdaterService do

  describe '#call' do
    let(:team)          { find_or_create :team_branston }
    let(:user)          { team.users.first }
    let(:kase)          { create :offender_sar_complaint, current_state: 'waiting_for_data', complaint_type: 'ico_complaint'}
    let(:state_machine) { double ConfigurableStateMachine::Machine, edit_case!: true }

    before(:each) do
      @service = ComplaintCaseUpdaterService.new(user, kase, params)
    end

    context 'when the case type the case state is updated' do
      let(:params) { 
        {
          "complaint_type"=>"litigation_complaint", 
          "priority"=>"normal"
        }
      }

      it 'also resets the case status to to_be_assessed' do
        @service.call

        expect(kase.current_state).to eq 'to_be_assessed'
      end
    end

    context 'when the case state is not updated but other details are' do
      let(:params) { 
        {
          "priority"=>"high"
        }
      }

      it 'the case state remains the same' do
        @service.call

        expect(kase.current_state).to eq 'waiting_for_data'
        expect(kase.priority).to eq 'high'
      end
    end

    context 'when the case state is not updated but the states contact details are' do
      let(:params) { 
        {
          "ico_contact_phone"=>"12323489", 
          "ico_reference"=>"test_ref_123",
          "priority"=>"high"
        }
      }

      it 'the case state remains the same' do
        @service.call

        expect(kase.current_state).to eq 'waiting_for_data'
        expect(kase.priority).to eq 'high'
      end
    end
  end
end
