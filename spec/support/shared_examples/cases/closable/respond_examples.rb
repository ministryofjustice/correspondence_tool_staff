require "rails_helper"

# Ensure a valid `kase` is declared in calling test
RSpec.shared_examples "respond spec" do |klass|
  describe klass do
    describe "#respond" do
      let(:manager) { find_or_create :disclosure_bmt_user }
      let(:another_responder) { create(:responder) }

      context "as an anonymous user" do
        it "redirects to sign_in" do
          expect(get(:respond, params: { id: kase.id }))
            .to redirect_to(new_user_session_path)
        end
      end

      context "as an authenticated manager" do
        before { sign_in manager }

        it "redirects to the application root" do
          expect(get(:respond, params: { id: kase.id }))
            .to redirect_to(manager_root_path)
        end
      end

      context "as the assigned responder" do
        before { sign_in responder }

        it "does not transition current_state" do
          expect(kase.current_state).to eq "awaiting_dispatch"
          get :respond, params: { id: kase.id }
          expect(kase.current_state).to eq "awaiting_dispatch"
        end

        it "renders the respond template" do
          expect(get(:respond, params: { id: kase.id }))
            .to render_template(:respond)
        end
      end

      context "as another responder" do
        before { sign_in another_responder }

        it "redirects to the application root" do
          expect(get(:respond, params: { id: kase.id }))
            .to redirect_to(responder_root_path)
        end
      end
    end
  end
end
