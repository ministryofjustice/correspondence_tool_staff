require 'rails_helper'

RSpec.describe CaseAttachmentsController, type: :controller do
  let(:drafter)  { kase.drafter }
  let(:assigner) { create :assigner }

  let(:kase)       { create(:case_with_response) }
  let(:attachment) { kase.attachments.first      }

  describe '#download' do
    shared_examples 'unauthorized user' do
      it 'redirect to the login or root page' do
        get :download, params: { case_id: kase.id, id: attachment.id }
        if subject.current_user
          expect(response).to redirect_to authenticated_root_path
        else
          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    context 'as an anonymous user' do
      it_behaves_like 'unauthorized user'
    end

    context 'as an assigner' do
      before { sign_in assigner }

      it "redirects to the attachment's url" do
        get :download, params: { case_id: kase.id, id: attachment.id}
        expect(response).to redirect_to attachment.url
      end
    end

    context 'as a drafter' do
      before { sign_in drafter }

      it "redirects to the attachment's url" do
        get :download, params: { case_id: kase.id, id: attachment.id}
        expect(response).to redirect_to attachment.url
      end
    end
  end

  describe '#destroy' do
    let(:attachment_path) { URI.parse(attachment.url).path[1..-1] }
    let(:attachment_object) do
      instance_double(
        Aws::S3::Object,
        delete: instance_double(Aws::S3::Types::DeleteObjectOutput)
      )
    end

    before do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(attachment_path)
                                         .and_return(attachment_object)
    end

    shared_examples 'unauthorized user' do
      it 'redirect to the login or root page' do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        if subject.current_user
          expect(response).to redirect_to authenticated_root_path
        else
          expect(response).to redirect_to new_user_session_path
        end
        expect(kase.reload.attachments).to include(attachment)
      end
    end

    context 'as an anonymous user' do
      it_behaves_like 'unauthorized user'
    end

    context 'as an assigner' do
      before { sign_in assigner }

      it_behaves_like 'unauthorized user'
    end

    context 'as a drafter' do
      before { sign_in drafter }

      it 'deletes the attachment from the case' do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        expect(kase.reload.attachments).not_to include(attachment)
      end
    end

  end
end
