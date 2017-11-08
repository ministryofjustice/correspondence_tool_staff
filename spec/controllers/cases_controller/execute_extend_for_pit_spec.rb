require "rails_helper"

describe CasesController, type: :controller do
  describe 'PATCH execute_extend_for_pit' do
    let(:case_being_drafted) { create :case_being_drafted }
    let(:manager)            { create :disclosure_bmt_user }
    let(:patch_params)       { { id: case_being_drafted.id,
                                 case: {
                                   external_deadline_yyyy: '2017',
                                   external_deadline_mm:   '02',
                                   external_deadline_dd:   '10',
                                   reason_for_extending:   'need more time',
                                 }
                               } }
    let(:cefps) { double(CaseExtendForPITService, call: :ok) }

    before do
      allow(CaseExtendForPITService).to receive(:new).and_return(cefps)
      sign_in manager
    end

    it 'authorizes' do
      expect {
        patch :execute_extend_for_pit, params: patch_params
      } .to require_permission(:execute_extend_for_pit?)
              .with_args(manager, case_being_drafted)
    end

    it 'calls the CaseExtendForPitService' do
      patch :execute_extend_for_pit, params: patch_params
      expect(CaseExtendForPITService)
        .to have_received(:new).with(manager,
                                     case_being_drafted,
                                     Date.new(2017, 2, 10),
                                     'need more time')
      expect(cefps).to have_received(:call)
    end

    it 'notifies the user of the success' do
      patch :execute_extend_for_pit, params: patch_params
      expect(flash[:notice])
        .to eq 'Case extended for Public Interest Test (PIT)'
    end

    context 'failed request' do
      let(:cefps) { double(CaseExtendForPITService, call: :error) }

      it 'notifies the user of the failure' do
        patch :execute_extend_for_pit, params: patch_params
        expect(flash[:alert])
          .to eq "Unable to perform PIT extension on case " +
                 case_being_drafted.number
      end
    end
  end
end
