require "rails_helper"

describe CasesController do
  let(:responder)     { find_or_create :foi_responder }
  let(:accepted_case) { create(:accepted_case) }

  before do
    sign_in responder
  end

  describe 'upload_responses' do
    it 'authorises' do
      expect {
        get :upload_responses, params: { id: accepted_case.id }
      }.to require_permission(:upload_responses?)
             .with_args(responder, accepted_case)

    end

    it 'renders the upload_responses template' do
      get :upload_responses, params: { id: accepted_case.id }

      expect(response).to have_rendered('cases/upload_responses')
    end
  end

  describe 'upload_responses_action' do
    let(:uploads_key) { "uploads/#{accepted_case.id}/responses/#{Faker::Internet.slug}.jpg" }
    let(:params) do
      {
        id:             accepted_case,
        type:           'response',
        uploaded_files: [uploads_key]
      }
    end

    it 'authorises' do
      expect {
        patch :upload_responses_action, params: params
      }.to require_permission(:upload_responses?)
             .with_args(responder, accepted_case)

    end

    let(:response_uploader) { double ResponseUploaderService, upload!: nil, result: :ok }
    let(:flash)             { MockFlash.new(action_params: 'upload')}

    context 'files specified without a comment' do
      before do
        allow_any_instance_of(CasesController).to receive(:flash)
                                                    .and_return(flash)
        allow(ResponseUploaderService).to receive(:new)
                                            .and_return(response_uploader)
      end

      it 'calls ResponseUploaderService' do
        patch :upload_responses_action, params: params

        expect(ResponseUploaderService).to have_received(:new).with(
                                             kase: accepted_case,
                                             current_user: responder,
                                             action: 'upload',
                                             uploaded_files: [uploads_key],
                                             upload_comment: nil
                                           )
        expect(response_uploader).to have_received(:upload!)
      end

      it 'redirects to the case detail page' do
        patch :upload_responses_action, params: params

        expect(response).to redirect_to(case_path(accepted_case))
      end

      it 'sets a flash message' do
        patch :upload_responses_action, params: params

        expect(flash[:notice])
          .to eq "You have uploaded the response for this case."
      end

    end

    context 'no files specified' do
      before do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        allow(ResponseUploaderService).to receive(:new).and_return(response_uploader)
        allow(response_uploader).to receive(:result).and_return(:blank)
      end

      it 're-renders the page' do
        patch :upload_responses_action, params: params

        expect(response).to have_rendered(:upload_responses)
      end

      it 'sets the flash alert' do
        patch :upload_responses_action, params: params

        expect(flash[:alert])
          .to eq 'Please select the file(s) you used in your response.'
      end
    end

    context 'there is an upload error' do
      before do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        allow(ResponseUploaderService).to receive(:new).and_return(response_uploader)
        allow(response_uploader).to receive(:result).and_return(:error)
      end

      it 're-renders the page if there is an upload error' do
        patch :upload_responses_action, params: params

        expect(response).to have_rendered(:upload_responses)
      end

      it 'sets the flash alert' do
        patch :upload_responses_action, params: params

        expect(flash[:alert])
          .to eq 'Errors detected with uploaded files.'
      end
    end
  end
end
