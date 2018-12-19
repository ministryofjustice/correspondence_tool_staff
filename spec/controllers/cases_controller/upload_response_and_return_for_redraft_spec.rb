require 'rails_helper'

describe CasesController, type: :controller do
  let(:responded_trigger_case) { create :pending_dacu_clearance_case }
  let(:approver)               { responded_trigger_case.approvers.first }

  describe 'upload_response_and_return_for_redraft' do
    let(:params) { { id: responded_trigger_case.id } }

    before do
      sign_in approver
    end

    it 'authorizes' do
      expect {
        get :upload_response_and_return_for_redraft, params: params
      } .to require_permission(:upload_response_and_return_for_redraft?)
              .with_args(approver, responded_trigger_case)
    end

    it 'renders the upload page' do
      get :upload_response_and_return_for_redraft, params: params

      expect(response)
        .to have_rendered('cases/upload_response_and_return_for_redraft')
    end

    it 'sets the case' do
      get :upload_response_and_return_for_redraft, params: params

      expect(assigns(:case)).to eq responded_trigger_case.decorate
    end
  end

  describe 'upload_response_and_return_for_redraft_action' do
    let(:uploads_key) { "uploads/#{responded_trigger_case.id}/responses/#{Faker::Internet.slug}.jpg" }
    let(:params) do
      {
        id: responded_trigger_case.id,
        type: 'response',
        uploaded_files: [uploads_key],
        draft_compliant: 'yes',
      }
    end
    let(:service) { instance_double(ResponseUploaderService,
                                    upload!: true,
                                    result: :ok) }

    before do
      sign_in approver
      allow(ResponseUploaderService).to receive(:new).and_return(service)
    end

    it 'authorizes' do
      expect {
        patch :upload_response_and_return_for_redraft_action, params: params
      } .to require_permission(:upload_response_and_return_for_redraft?)
              .with_args(approver, responded_trigger_case)
    end

    it 'calls the response upload service' do
      patch :upload_response_and_return_for_redraft_action, params: params
      expect(ResponseUploaderService).to have_received(:new).with(
                                           hash_including(
                                             current_user: approver,
                                             kase: responded_trigger_case,
                                             action: 'upload-redraft',
                                             upload_comment: nil,
                                             uploaded_files: [uploads_key],
                                             is_compliant: true,
                                           )
                                         )

      expect(service).to have_received(:upload!)
    end

    context 'successful action' do
      it 'flashes a notification' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(flash[:notice])
          .to eq "You have uploaded the response for this case."
      end

      it 'redirects to case detail page' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(response).to redirect_to(case_path(responded_trigger_case))
      end

      it 'sets permitted events' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(assigns[:permitted_events]).not_to be_nil
      end
    end

    context 'uploaded_files is blank' do
      before do
        allow(service).to receive(:result).and_return(:blank)
      end

      it 'flashes an error' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(flash[:alert])
          .to eq 'Please select the file(s) you used in your response.'
      end

      it 'renders the upload_response_and_return_for_redraft page' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(response).to have_rendered('cases/upload_response_and_return_for_redraft')
      end
    end

    context 'error in uploader service' do
      before do
        allow(service).to receive(:result).and_return(:error)
      end

      it 'flashes an error' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(flash[:alert]).to eq 'Errors detected with uploaded files.'
      end

      it 'renders the upload_response_and_return_for_redraft page' do
        patch :upload_response_and_return_for_redraft_action, params: params
        expect(response).to have_rendered('cases/upload_response_and_return_for_redraft')
      end
    end
  end
end
