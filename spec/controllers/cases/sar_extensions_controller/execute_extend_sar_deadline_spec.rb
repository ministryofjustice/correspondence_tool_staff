require "rails_helper"

describe Cases::SarExtensionsController, type: :controller do
  describe '#create' do
    let(:sar_case) { create :approved_sar }
    let(:manager)  { find_or_create :disclosure_bmt_user }

    let(:service) {
      double(CaseExtendSARDeadlineService, call: :ok, result: :ok)
    }

    let(:post_params)  {
      {
        case_id: sar_case.id,
        case: {
          extension_period:      '11',
          reason_for_extending:  'need more time',
        }
      }
    }

    before do
      allow(CaseExtendSARDeadlineService).to receive(:new).and_return(service)
      sign_in manager
    end

    it 'authorizes' do
      expect { post :create, params: post_params }
        .to require_permission(:extend_sar_deadline?).with_args(manager, sar_case)
    end

    context 'with valid params' do
      before do
        post :create, params: post_params
      end

      it 'calls the CaseExtendSARDeadlineService' do
        expect(CaseExtendSARDeadlineService).to(
          have_received(:new)
          .with(
            user: manager,
            kase: sar_case,
            extension_days: '11',
            reason: 'need more time'
          )
        )

        expect(service).to have_received(:call)
      end

      it 'notifies the user of the success' do
        expect(request.flash[:notice]).to eq 'Case extended for SAR'
      end
    end

    context 'with invalid params' do
      let(:service) {
        double(
          CaseExtendSARDeadlineService,
          call: :validation_error,
          result: :validation_error
        )
      }

      it 'renders the new page' do
        post :create, params: post_params
        expect(:result).to have_rendered(:new)
      end
    end

    context 'failed request' do
      let(:service) {
        double(
          CaseExtendSARDeadlineService,
          call: :error,
          result: :error
        )
      }

      it 'notifies the user of the failure' do
        post :create, params: post_params
        expected_message = "Unable to perform SAR extension on case #{sar_case.number}"

        expect(request.flash[:alert]).to eq expected_message
        expect(:result).to redirect_to(case_path(sar_case.id))
      end
    end
  end
end
