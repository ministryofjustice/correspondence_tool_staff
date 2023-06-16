require "rails_helper"

# Ensure a valid `kase` is declared in calling test
RSpec.shared_examples "edit closure spec" do |klass|
  describe klass do
    before do
      sign_in manager
    end

    it "authorises with update_closure? policy" do
      expect {
        get :edit_closure, params: { id: kase.id }
      }.to require_permission(:update_closure?)
        .with_args(manager, kase)
    end

    it "renders the close page" do
      get :edit_closure, params: { id: kase.id }
      expect(response).to render_template :edit_closure
    end
  end
end
