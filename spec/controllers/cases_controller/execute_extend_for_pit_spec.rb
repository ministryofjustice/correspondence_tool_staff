require "rails_helper"

describe CasesController, type: :controller do
  describe 'PATCH execute_extend_for_pit' do
    let(:case_being_drafted)   { create :case_being_drafted,
                                :flagged_accepted,
                                approver: specialist }
    let(:specialist)         { create :disclosure_specialist }
    let(:patch_params)       { { id: case_being_drafted.id,
                                 case: {
                                   extension_deadline_yyyy: '2017',
                                   extension_deadline_mm:   '02',
                                   extension_deadline_dd:   '10',
                                   reason_for_extending:   'need more time',
                                 }
                               } }
    let(:service) { double(CaseExtendForPITService, call: :ok) }

    before do
      allow(CaseExtendForPITService).to receive(:new).and_return(service)
      sign_in specialist
    end

    it 'authorizes' do
      expect {
        patch :execute_extend_for_pit, params: patch_params
      } .to require_permission(:extend_for_pit?)
              .with_args(specialist, case_being_drafted)
    end

    it 'calls the CaseExtendForPitService' do
      patch :execute_extend_for_pit, params: patch_params
      expect(CaseExtendForPITService)
        .to have_received(:new).with(specialist,
                                     case_being_drafted,
                                     Date.new(2017, 2, 10),
                                     'need more time')
      expect(service).to have_received(:call)
    end

    it 'notifies the user of the success' do
      patch :execute_extend_for_pit, params: patch_params
      expect(flash[:notice])
        .to eq 'Case extended for Public Interest Test (PIT)'
    end

    context 'validation error' do
      let(:service) { double(CaseExtendForPITService, call: :validation_error) }

      it 'renders the exent_for_pit page' do
        patch :execute_extend_for_pit, params: patch_params
        expect(:result).to have_rendered(:extend_for_pit)
      end
    end

    context 'failed request' do
      let(:service) { double(CaseExtendForPITService, call: :error) }

      it 'notifies the user of the failure' do
        patch :execute_extend_for_pit, params: patch_params
        expect(flash[:alert])
          .to eq "Unable to perform PIT extension on case " +
                 case_being_drafted.number
        expect(:result).to redirect_to(case_path(case_being_drafted.id))
      end
    end
  end
end
