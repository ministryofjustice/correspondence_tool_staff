require "rails_helper"

RSpec.describe Cases::LinksController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:kase)    { create :case }
  let(:link_case) { create :case }

  describe "#new" do
    before do
      sign_in manager
    end

    it "authorizes" do
      expect { get :new, params: { case_id: kase.id } }
        .to require_permission(:new_case_link?).with_args(manager, kase)
    end

    it "sets @case" do
      get :new, params: { case_id: kase.id }
      expect(assigns(:case)).to eq kase
    end

    it "renders the template" do
      get :new, params: { case_id: kase.id }
      expect(response).to render_template(:new)
    end
  end

  describe "#create" do
    let(:service) { double(CaseLinkingService, create!: :ok) }
    let(:post_params) do
      {
        case_id: kase.id,
        case: {
          number_to_link: link_case.number,
        },
      }
    end

    before do
      allow(CaseLinkingService).to receive(:new).and_return(service)
      sign_in manager
    end

    it "authorizes" do
      expect { post :create, params: post_params }
        .to require_permission(:new_case_link?).with_args(manager, kase)
    end

    it "calls the CaseLinkingService create method" do
      post :create, params: post_params

      expect(CaseLinkingService).to have_received(:new).with(
        manager,
        kase,
        post_params[:case][:number_to_link],
      )

      expect(service).to have_received(:create!)
    end

    it "notifies the user of the success" do
      post :create, params: post_params
      expect(flash[:notice]).to eq "Case #{link_case.number} has been linked to this case"
    end

    context "with validation error" do
      let(:service) { double(CaseLinkingService, create!: :validation_error) }

      it "renders the new_link page" do
        post :create, params: post_params
        expect(request).to have_rendered(:new)
      end
    end

    context "when failed request" do
      let(:service) { double(CaseLinkingService, create!: :error) }

      it "notifies the user of the failure" do
        post :create, params: post_params
        expect(flash[:alert]).to eq "Unable to create a link to case #{link_case.number}"
        expect(request).to redirect_to(case_path(kase.id))
      end
    end
  end

  describe "#destroy" do
    let(:service) { double(CaseLinkingService, destroy!: :ok) }
    let(:delete_params) do
      {
        case_id: kase.id, id: link_case.number
      }
    end

    before do
      allow(CaseLinkingService).to receive(:new).and_return(service)
      sign_in manager
    end

    it "authorizes" do
      expect { delete :destroy, params: delete_params }
        .to require_permission(:new_case_link?).with_args(manager, kase)
    end

    it "calls the CaseLinkingService destroy method" do
      delete :destroy, params: delete_params

      expect(CaseLinkingService)
        .to have_received(:new).with(
          manager,
          kase,
          delete_params[:id],
        )
      expect(service).to have_received(:destroy!)
    end

    it "notifies the user of the success" do
      delete :destroy, params: delete_params
      expect(flash[:notice])
        .to eq "The link to case #{link_case.number} has been removed."
    end

    context "when failed request" do
      let(:service) { double(CaseLinkingService, destroy!: :failed) }

      it "notifies the user of the failure" do
        delete :destroy, params: delete_params
        expect(flash[:alert])
          .to eq "Unable to remove the link to case #{link_case.number}"
        expect(request).to redirect_to(case_path(kase.id))
      end
    end
  end
end
