require 'rails_helper'

RSpec.describe CaseAttachmentsController, type: :controller do
  describe '#download' do
    let(:kase)       { create(:case_with_response) }
    let(:attachment) { kase.attachments.first      }

    before do
      sign_in user
    end

    context 'as a drafter' do
      let(:user) { create :drafter }

      it "redirects to the attachment's url" do
        get :download, params: { case_id: kase.id, id: attachment.id}
        expect(response).to redirect_to attachment.url
      end
    end
  end
end
