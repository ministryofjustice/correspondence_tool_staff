require 'rails_helper'

RSpec.describe CaseAttachmentsController, type: :controller do
  let(:responder) { kase.responder }
  let(:manager)   { create :manager }

  let(:s3_key) { "uploads/#{kase.id}/request/request.pdf" }

  before :each do
    stub_s3_uploader_for_all_files!
  end

  describe 'POST create' do
    let(:kase)   { create :case_being_drafted }
    let(:params) {
      {
        case_id: kase.id,
        case_attachment: {
          key: s3_key,
          type: 'response'
        }
      }
    }

    before do
      sign_in responder
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end

    it 'authorises' do
      expect {
        post :create, params: params
      } .to require_permission(:can_add_attachment?)
              .with_args(responder, kase)

    end

    it 'creates the attachment' do
      post :create, params: params

      expect(kase.attachments.reload.count).to eq 1
      expect(kase.attachments.last.key).to eq s3_key
    end

    it 'defaults the state to "unprocessed"' do
      post :create, params: params

      expect(kase.attachments.last.state).to eq 'unprocessed'
    end

    it 'starts the virus scan job' do
      post :create, params: params

      expect(VirusScanJob).to have_been_enqueued.exactly(:once)
    end

    it 'redirects to status page' do
      post :create, params: params

      attachment = kase.attachments.last
      expect(response).to redirect_to case_attachment_path(
                                        case_id: kase.id,
                                        id: attachment.id
                                      )
    end
  end

  describe 'GET preview' do
    it 'sends the file inline'
  end

  describe 'GET show' do
    let(:kase) { create(:case_with_response, responder: responder) }
    let(:attachment) { kase.attachments.first }

    before do
      sign_in responder
    end

    it 'returns JSON version of object if requested' do
      get :show, params: { case_id: kase.id, id: attachment.id }

      expect(response.body).to eq attachment.to_json
    end
  end

  describe '#download' do
    let(:kase) { create(:case_with_response, responder: responder) }
    let(:attachment) { kase.attachments.first }


    shared_examples 'unauthorized user' do
      it 'redirect to the login or root page' do
        get :download, params: { case_id: kase.id, id: attachment.id }
        if subject.current_user
          if subject.current_user.manager?
            expect(response).to redirect_to manager_root_path
          elsif subject.current_user.responder?
             expect(response).to redirect_to manager_root_path
          end
        else
          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    shared_examples 'an authorized user' do
      let(:presigned_url) { "http://pre-signed.com/url" }
      let(:object) { instance_double Aws::S3::Object,
                                     presigned_url: presigned_url }
      before do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attachment.key)
                                           .and_return(object)
      end

      it "redirects to the attachment's url" do
        get :download, params: { case_id: kase.id, id: attachment.id}
        expect(response).to redirect_to presigned_url
      end
    end

    context 'as an anonymous user' do
      it_behaves_like 'unauthorized user'
    end

    context 'as a manager' do
      before { sign_in manager }

      it_behaves_like 'an authorized user'
    end

    context 'as a responder' do
      before { sign_in responder }

      it_behaves_like 'an authorized user'
    end
  end

  describe '#destroy' do
    let(:kase)       { create :case_with_response, responder: responder }
    let(:attachment) { kase.attachments.first }
    let(:attachment_object) do
      CASE_UPLOADS_S3_BUCKET.object(attachment.key)
    end
    let(:preview_object) do
      CASE_UPLOADS_S3_BUCKET.object(attachment.preview_key)
    end

    shared_examples 'unauthorized user' do
      it 'redirect to the login or root page' do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        if subject.current_user
          if subject.current_user.manager?
            expect(response).to redirect_to manager_root_path
          elsif subject.current_user.responder?
            expect(response).to redirect_to manager_root_path
          end
        else
          expect(response).to redirect_to new_user_session_path
        end
        expect(kase.reload.attachments).to include(attachment)
      end
    end

    context 'as an anonymous user' do
      it_behaves_like 'unauthorized user'
    end

    context 'as a manager with a case that is still open' do
      before { sign_in manager }

      it_behaves_like 'unauthorized user'
    end

    context 'as a manager with a case that is still open' do
      before { sign_in manager }

      it_behaves_like 'unauthorized user'
    end

    context 'as a manager with a case that has been marked as responded' do
      let(:kase) { create(:responded_case) }

      before { sign_in manager }

      it_behaves_like 'unauthorized user'
    end

    context 'as a responder who is still responding to a case' do
      before { sign_in responder }

      it 'deletes the attachment from the case' do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        expect(kase.reload.attachments).not_to include(attachment)
      end
    end

    context 'as a responder who has marked the case as responded' do
      let(:kase) { create(:responded_case) }

      before { sign_in responder }

      it_behaves_like 'unauthorized user'
    end
  end
end
