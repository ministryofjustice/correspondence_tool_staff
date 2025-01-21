require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  let(:user) { create(:user) }

  xdescribe "#maintenance_mode" do
    before do
      sign_in user
    end

    context "when maintenance mode is off" do
      it "redirects requests for the maintenance page to the homepage" do
        get :maintenance_mode
        expect(response).to redirect_to("/")
      end
    end

    context "when maintenance mode is on" do
      before do
        allow(controller).to receive(:maintenance_mode_on?).and_return true
      end

      it "renders the maintenance page" do
        get :maintenance_mode
        expect(response).to render_template(:maintenance)
      end

      it "redirects other requests to the maintenance page" do
        @controller = Cases::FiltersController.new
        get :open
        expect(response).to redirect_to("/maintenance")
      end
    end
  end
end
