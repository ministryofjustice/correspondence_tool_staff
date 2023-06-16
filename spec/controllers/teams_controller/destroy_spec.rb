require "rails_helper"

RSpec.describe TeamsController, type: :controller do
  describe "DELETE destroy" do
    let(:responder) { find_or_create :foi_responder }
    let(:dir)       { create :directorate, business_group: bg }
    let(:bg)        { create :business_group }
    let(:manager)   { create :manager }
    let(:params) do
      {
        id: dir.id,
      }
    end

    context "signed in as manager" do
      before { sign_in manager }

      it "calls user deletion service" do
        service = double(TeamDeletionService)
        expect(TeamDeletionService).to receive(:new).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:ok)
        delete :destroy, params:
      end

      context "response :ok" do
        before do
          service = double(TeamDeletionService)
          expect(TeamDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:ok)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:notice]).to eq(
            "#{dir.name} directorate has now been deactivated",
          )
        end

        context "deactivating a directorate" do
          it "redirects to parent team path" do
            expect(response).to redirect_to(team_path(bg))
          end
        end

        context "deactivating a business group" do
          let(:bg)      { create :business_group }
          let(:params)  { { id: bg.id } }

          it "redirects to team path" do
            expect(response).to redirect_to(teams_path)
          end
        end
      end

      context "response :error" do
        before do
          service = double(TeamDeletionService)
          expect(TeamDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:incomplete)
          delete :destroy, params:
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(dir))
        end
      end
    end

    context "signed in as non-manager" do
      before do
        sign_in responder
        delete :destroy, params:
      end

      it "displays a flash notice" do
        expect(flash["alert"]).to eq "You are not authorised to deactivate teams"
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
