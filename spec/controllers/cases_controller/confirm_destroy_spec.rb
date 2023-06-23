require "rails_helper"

describe CasesController, type: :controller do # rubocop:disable RSpec/FilePath
  describe "GET confirm_destroy" do
    let(:manager)           { create :manager }
    let(:unassigned_case)   { create :case }
    let(:params)            { { id: unassigned_case.id } }

    before { sign_in manager }

    it "authorises" do
      expect {
        get :confirm_destroy, params:
      }.to require_permission(:confirm_destroy?)
               .with_args(manager, unassigned_case)
    end

    it "sets @case" do
      get(:confirm_destroy, params:)
      expect(assigns(:case)).to eq unassigned_case
    end

    it "renders the confirmation page" do
      get(:confirm_destroy, params:)
      expect(response).to render_template(:confirm_destroy)
    end
  end
end
