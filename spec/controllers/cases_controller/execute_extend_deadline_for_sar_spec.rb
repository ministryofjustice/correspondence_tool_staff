require "rails_helper"

describe CasesController, type: :controller do
  describe 'PATCH execute_extend_deadline_for_sar' do
    let(:sar_case)      { create :sar_case }
    let(:manager)       { find_or_create :disclosure_bmt_user }
    let(:service) { double(CaseExtendDeadlineForSARService, call: :ok) }
    let(:patch_params)  {
                          {
                            id: sar_case.id,
                            case: {
                              extension_deadline_yyyy: '2017',
                              extension_deadline_mm:   '02',
                              extension_deadline_dd:   '10',
                              reason_for_extending:   'need more time',
                            }
                          }
                        }

    before do
      allow(CaseExtendDeadlineForSARService).to receive(:new).and_return(service)
      sign_in manager
    end

    it 'authorizes' do
      expect {
        patch :execute_extend_deadline_for_sar, params: patch_params
      }.to require_permission(:extend_deadline_for_sar?).with_args(manager, sar_case)
    end

    it 'calls the CaseExtendDeadlineForSARService' do
      patch :execute_extend_deadline_for_sar, params: patch_params

      expect(CaseExtendDeadlineForSARService).to(
        have_received(:new)
        .with(manager, sar_case, Date.new(2017, 2, 10), 'need more time')
      )

      expect(service).to have_received(:call)
    end

    it 'notifies the user of the success' do
      patch :execute_extend_deadline_for_sar, params: patch_params

      expect(flash[:notice]).to eq 'Case extended for SAR'
    end

    context 'validation error' do
      let(:service) { double(CaseExtendDeadlineForSARService, call: :validation_error) }

      it 'renders the extend_deadline_for_sar page' do
        patch :execute_extend_deadline_for_sar, params: patch_params
        expect(:result).to have_rendered(:extend_deadline_for_sar)
      end
    end

    context 'failed request' do
      let(:service) { double(CaseExtendDeadlineForSARService, call: :error) }

      it 'notifies the user of the failure' do
        patch :execute_extend_deadline_for_sar, params: patch_params
        expected_message = "Unable to perform SAR extension on case #{sar_case.number}"

        expect(flash[:alert]).to eq expected_message
        expect(:result).to redirect_to(case_path(sar_case.id))
      end
    end
  end
end
