require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:team_admin) { find_or_create :team_admin }
  let(:dacu)    { find_or_create :team_dacu }

  describe "GET show" do
    let(:service)                         { double UserActiveCaseCountService }
    let(:unpaginated_cases)               { double "Unapaginated cases collection", page: paginated_cases, decorate: all_decorated_cases }
    let(:paginated_cases)                 { double "Paginated cases collection", decorate: paginated_decorated_cases }
    let(:paginated_decorated_cases)       { double "Paginaged decorated_cases" }
    let(:all_decorated_cases)             { double "Unpaginated decorated cases" }

    before { sign_in manager }

    it "returns success" do
      get :show, params: { id: manager.id }
      expect(response).to be_successful
    end

    context "html request" do
      it "assigns case to paginated decorated case list" do
        expect(UserActiveCaseCountService).to receive(:new).and_return(service)
        expect(service).to receive(:active_cases_for_user).with(manager).and_return(unpaginated_cases)
        get :show, params: { id: manager.id }

        expect(assigns(:cases)).to eq paginated_decorated_cases
      end

      it "renders show template" do
        get :show, params: { id: manager.id }
        expect(response).to render_template(:show)
      end
    end

    context "csv request" do
      let(:csv_case) { double("Example Case") }

      it "returns the csv file in the body" do
        # so that the filename is fixed
        Timecop.freeze Time.zone.local(2018, 11, 9, 13, 48, 22) do
          allow(UserActiveCaseCountService).to receive(:new).and_return(service)
          allow(service).to receive(:active_cases_for_user).with(manager).and_return(unpaginated_cases)
          expect(all_decorated_cases).to receive(:each).and_yield(csv_case)
          expect(csv_case).to receive(:to_csv).and_return(%w[a csv file])

          get :show, format: "csv", params: { id: manager.id }
          expect(response).to be_successful

          expect(response.headers["Content-Disposition"])
            .to eq 'attachment; filename="disclosure-bmt_managing_user-cases-18-11-09-134822.csv"'
          expect(response.headers["Content-Type"]).to eq "text/csv; charset=utf-8"

          expect(response.body.delete('"')).to eq [CSVExporter::CSV_COLUMN_HEADINGS.join(","),
                                                   "a,csv,file\n"].join("\n")
        end
      end
    end
  end

  describe "POST create", versioning: true do
    let(:params) do
      {
        user: {
          full_name: "TEst Er",
          email: "test.er@localhost",
        },
        team_id: dacu.id,
      }
    end

    let(:params_with_spaces_around) do
      {
        user: {
          full_name: "  TEst Er  ",
          email: "test.er@localhost",
        },
        team_id: dacu.id,
      }
    end

    before { sign_in manager }

    it "creates a user with the given params" do
      post(:create, params:)

      expect(User.last).to have_attributes full_name: "TEst Er",
                                           email: "test.er@localhost"
    end

    it "creates a user with a name being wrapped with spaces " do
      post :create, params: params_with_spaces_around

      expect(User.last).to have_attributes full_name: "TEst Er",
                                           email: "test.er@localhost"
    end

    it "sets the user password to something random" do
      allow(SecureRandom).to receive(:random_number).with(any_args)
                               .and_return(7_271_817_273_818_812)
      post(:create, params:)
      user = User.last
      expect(user.valid_password?(SecureRandom.random_number(36**13).to_s(36))).to be true
    end

    it "adds the user to the specified team" do
      post(:create, params:)

      expect(User.last.teams).to eq [dacu]
    end

    it "redirects to the users list if not team specified" do
      post(:create, params:)
      expect(response).to redirect_to(team_path(dacu.id))
    end

    context "with a team_id param" do
      let!(:dacu) { find_or_create :team_dacu }

      before do
        params[:team_id] = dacu.id
        params[:role]    = "manager"
      end

      it "adds the user to the given team with the given role" do
        post(:create, params:)

        expect(dacu.managers).to include User.last
      end

      it "redirects to the team details page" do
        post(:create, params:)
        expect(response).to redirect_to(team_path(id: dacu.id))
      end

      it "adds the existing user to new given team with the given role" do
        responder = find_or_create :foi_responder
        test_params = {
          user: {
            full_name: "  #{responder.full_name}  ",
            email: responder.email,
          },
          team_id: dacu.id,
        }
        post :create, params: test_params

        responder.reload
        expect(dacu.managers).to include responder
        expect(responder.teams).to include dacu
      end
    end

    it "records the id of the user who is creating a new user" do
      post(:create, params:)
      whodunnit = User.last.versions.last.whodunnit.to_i
      expect(whodunnit).to eq manager.id
    end
  end

  describe "PATCH update", versioning: true do
    before { sign_in manager }

    let(:user) { create :user, full_name: "John Smith", email: "js@moj.com" }
    let(:team) { create :team }
    let(:params) do
      {
        "team_id" => team.id.to_s,
        "role" => "responder",
        "user" => {
          "full_name" => "Joanne Smythe",
          "email" => "correspondence-staff-dev+joanne.smythe@digital.justice.gov.uk",
        },
        "commit" => "Edit information officer",
        "id" => user.id.to_s,
      }
    end

    context "valid updates" do
      it "updates the user" do
        patch(:update, params:)

        expect(user.reload.full_name).to eq "Joanne Smythe"
        expect(user.email).to eq "correspondence-staff-dev+joanne.smythe@digital.justice.gov.uk"
      end

      it "redirects to team page" do
        patch(:update, params:)
        expect(response).to redirect_to(team_path(team.id))
      end

      it "records the id of the user who is performing an update" do
        patch(:update, params:)
        whodunnit = user.versions.last.whodunnit.to_i
        expect(whodunnit).to eq manager.id
      end
    end

    context "invalid update" do
      let!(:existing_user) { create :user, full_name: "John Smith", email: "eu@moj.com" }
      let(:params) do
        {
          "team_id" => team.id.to_s,
          "role" => "responder",
          "user" => {
            "full_name" => "Joanne Smythe",
            "email" => "eu@moj.com",
          },
          "commit" => "Edit information officer",
          "id" => user.id.to_s,
        }
      end

      it "does not update the user" do
        patch(:update, params:)
        expect(user.reload.email).to eq "js@moj.com"
      end

      it "redisplays the edit page" do
        patch(:update, params:)
        expect(response).to render_template :edit
      end
    end
  end

  describe "GET new" do
    let(:params) do
      { team_id: dacu.id,
        role: "manager" }
    end

    before { sign_in manager }

    it "creates a new user" do
      get(:new, params:)
      expect(assigns(:user)).to be_a User
      expect(assigns(:user).persisted?).to eq false
    end

    it "assigns the team" do
      get(:new, params:)
      expect(assigns(:team)).to eq dacu
    end

    it "assigns the role" do
      get(:new, params:)
      expect(assigns(:role)).to eq "manager"
    end

    it "returns an error if the team does not support the given role" do
      expect {
        get :new, params: params.merge(role: "unsupported")
      }.to raise_error(RuntimeError)
    end
  end

  describe "DELETE destroy" do
    let(:responder) { find_or_create :foi_responder }
    let(:team)      { create :responding_team }
    let(:params) do
      {
        id: responder.id,
        team_id: team.id,
      }
    end

    context "signed in as team_admin" do
      before { sign_in team_admin }

      it "calls user deletion service" do
        service = double(UserDeletionService)
        expect(UserDeletionService).to receive(:new).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:ok)
        delete :destroy, params:
      end

      context "response :ok" do
        before do
          service = double(UserDeletionService)
          expect(UserDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:ok)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:notice]).to eq I18n.t("devise.registrations.destroyed")
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(team))
        end
      end

      context "response :has_live_cases" do
        before do
          service = double(UserDeletionService)
          expect(UserDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:has_live_cases)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:alert]).to eq I18n.t("devise.registrations.has_live_cases")
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(team))
        end
      end

      context "response :error" do
        before do
          service = double(UserDeletionService)
          expect(UserDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:error)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:alert]).to eq I18n.t("devise.registrations.error")
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(team))
        end
      end
    end

    context "signed in as manager" do
      before { sign_in manager }

      it "calls user deletion service" do
        service = double(UserDeletionService)
        expect(UserDeletionService).to receive(:new).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:result).and_return(:ok)
        delete :destroy, params:
      end

      context "response :ok" do
        before do
          service = double(UserDeletionService)
          expect(UserDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:ok)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:notice]).to eq I18n.t("devise.registrations.destroyed")
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(team))
        end
      end

      context "response :has_live_cases" do
        before do
          service = double(UserDeletionService)
          expect(UserDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:has_live_cases)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:alert]).to eq I18n.t("devise.registrations.has_live_cases")
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(team))
        end
      end

      context "response :error" do
        before do
          service = double(UserDeletionService)
          expect(UserDeletionService).to receive(:new).and_return(service)
          expect(service).to receive(:call)
          expect(service).to receive(:result).and_return(:error)
          delete :destroy, params:
        end

        it "displays a flash notice" do
          expect(flash[:alert]).to eq I18n.t("devise.registrations.error")
        end

        it "redirects to team path" do
          expect(response).to redirect_to(team_path(team))
        end
      end
    end

    context "signed in as non-manager" do
      before do
        sign_in responder
        delete :destroy, params:
      end

      it "displays a flash notice" do
        expect(flash["alert"]).to eq "You are not authorised to deactivate users"
      end

      it "redirects to root" do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
