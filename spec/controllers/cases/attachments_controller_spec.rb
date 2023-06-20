require "rails_helper"

RSpec.describe Cases::AttachmentsController, type: :controller do
  let(:responder) { kase.responder }
  let(:manager)   { create :manager }

  let(:kase)       { create(:case_with_response) }
  let(:attachment) { kase.attachments.first      }

  describe "#download" do
    shared_examples "unauthorized user" do
      it "redirect to the login or root page" do
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

    shared_examples "an authorized user" do
      let(:presigned_url) { "http://pre-signed.com/url" }
      let(:object) do
        instance_double Aws::S3::Object,
                        presigned_url:
      end
      before do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attachment.key)
                                           .and_return(object)
      end

      it "redirects to the attachment's url" do
        get :download, params: { case_id: kase.id, id: attachment.id }
        expect(response).to redirect_to presigned_url
      end
    end

    context "when an anonymous user" do
      it_behaves_like "unauthorized user"
    end

    context "when a manager" do
      before { sign_in manager }

      it_behaves_like "an authorized user"
    end

    context "when a responder" do
      before { sign_in responder }

      it_behaves_like "an authorized user"
    end
  end

  describe "#destroy" do
    let(:attachment_object) do
      instance_double(
        Aws::S3::Object,
        delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
      )
    end
    let(:preview_object) do
      instance_double(
        Aws::S3::Object,
        delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
      )
    end

    before do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(attachment.key)
                                         .and_return(attachment_object)
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(attachment.preview_key)
                                         .and_return(preview_object)
    end

    shared_examples "unauthorized user" do
      it "redirect to the login or root page" do
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

    context "when an anonymous user" do
      it_behaves_like "unauthorized user"
    end

    context "when a manager with a case that is still open" do
      before { sign_in manager }

      it_behaves_like "unauthorized user"
    end

    context "when a manager with a case that is still open" do
      before { sign_in manager }

      it_behaves_like "unauthorized user"
    end

    context "when a manager with a case that has been marked as responded" do
      let(:kase) { create(:responded_case) }

      before { sign_in manager }

      it_behaves_like "unauthorized user"
    end

    context "when a responder who is still responding to a case" do
      before { sign_in responder }

      it "deletes the attachment from the case" do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        expect(kase.reload.attachments).not_to include(attachment)
      end
    end

    context "when a responder who has marked the case as responded" do
      let(:kase) { create(:responded_case) }

      before { sign_in responder }

      it_behaves_like "unauthorized user"
    end
  end
end
