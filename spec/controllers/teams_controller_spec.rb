require "rails_helper"

RSpec.describe TeamsController, type: :controller do
  let(:bg)              { find_or_create :responder_business_group }
  let(:another_bg)      { create :business_group }
  let(:directorate)     { find_or_create :responder_directorate }
  let(:business_unit)   { find_or_create :foi_responding_team }
  let(:business_unit2)  { find_or_create :sar_responding_team }
  let(:manager)         { create :manager }
  let(:business_map)    { find_or_create(:report_type, :r006) }
  let(:reports)         { [business_map] }
  let(:foi_responder)   { find_or_create(:foi_responder) }

  describe "GET index" do
    context "when logged in as a manager" do
      before { sign_in manager }

      it "loads all business groups" do
        allow(Team).to receive(:where).with(type: "BusinessGroup").and_return(BusinessGroup.order(:name))
        get :index
        expect(assigns(:teams)).to eq BusinessGroup.order(:name)
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context "when logged in as a non-manager" do
      before do
        business_unit2.responders << foi_responder
        sign_in foi_responder
      end

      it "loads all teams the the responder is a member of" do
        get :index
        expect(assigns(:teams)).to eq [business_unit, business_unit2]
        expect(assigns(:reports)).to eq reports
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template(:teams_for_user)
      end
    end
  end

  describe "GET show" do
    context "when logged in as a manager" do
      let(:directorate2) { create :directorate, business_group: bg }

      before do
        sign_in manager
      end

      it "loads the team, children and business map" do
        get :show, params: { id: bg.id }
        expect(assigns(:team)).to eq bg
        expect(assigns(:children)).to match_array [directorate, directorate2]
        expect(assigns(:reports)).to eq reports
      end

      it "renders the show template" do
        get :show, params: { id: bg.id }
        expect(response).to render_template(:show)
      end

      context "when viewing a business group" do
        it "has no active users" do
          get :show, params: { id: bg.id }
          expect(assigns(:active_users)).to be_empty
        end
      end

      context "when viewing a business unit" do
        let!(:user_1) { find_or_create :foi_responder }
        let!(:user_2) { create :foi_responder, identifier: "foi responder 2" }

        it "assigns active users" do
          get :show, params: { id: business_unit.id }
          expect(assigns(:active_users)).to match_array [user_1, user_2]
        end

        it "calls UserActiveCaseCountService to populate case_counts" do
          counts = { user_1.id => 34, user_2.id => 6 }
          service = instance_double UserActiveCaseCountService
          allow(UserActiveCaseCountService).to receive(:new).and_return(service)
          allow(service).to receive(:case_counts_by_user).with([user_2, user_1]).and_return(counts)

          get :show, params: { id: business_unit.id }
          expect(assigns(:case_counts)).to eq counts
        end
      end
    end

    context "when logged in as a non-manager" do
      before do
        sign_in foi_responder
      end

      context "when viewing a team that he is a member of" do
        it "loads the team" do
          get :show, params: { id: business_unit.id }
        end
      end

      context "when viewing a team that he isnt a member of" do
        it "loads the team and children" do
          get :show, params: { id: business_unit.id }
          expect(assigns(:team)).to eq business_unit
          expect(assigns(:children)).to be_empty
          expect(assigns(:reports)).to eq reports
        end

        it "renders the show template" do
          get :show, params: { id: business_unit.id }
          expect(response).to render_template(:show)
        end
      end
    end
  end

  describe "POST create", versioning: true do
    context "when signed in as a manager" do
      before { sign_in manager }

      describe "POST create" do
        let(:params) do
          {
            "team" => {
              "name" => "Frog sizing unit",
              "email" => "frogs@a.com",
              "team_lead" => "Stephen Richards",
              "parent_id" => directorate.id,
              "role" => "responder",
              "correspondence_type_ids" => [CorrespondenceType.sar.id.to_s],
            },
            "team_type" => "bu",
            "commit" => "Submit",
          }
        end

        let(:params_foi_access) do
          {
            "team" => {
              "name" => "Frog sizing unit",
              "email" => "frogs@a.com",
              "team_lead" => "Stephen Richards",
              "parent_id" => directorate.id,
              "role" => "responder",
              "correspondence_type_ids" => [CorrespondenceType.foi.id.to_s],
            },
            "team_type" => "bu",
            "commit" => "Submit",
          }
        end

        it "creates a business unit with the given params" do
          post(:create, params:)

          bu = BusinessUnit.last
          expect(bu.name).to eq "Frog sizing unit"
          expect(bu.email).to eq "frogs@a.com"
          expect(bu.team_lead).to eq "Stephen Richards"
          expect(bu.parent).to eq directorate
        end

        it "records the id of the user creating" do
          post(:create, params:)
          whodunnit = BusinessUnit.last.versions.last.whodunnit.to_i
          expect(whodunnit).to eq manager.id
        end

        context "and SAR IR access" do
          it "adds access if SAR access is enabled" do
            post(:create, params:)
            bu = BusinessUnit.last

            ctrs_ids = bu.correspondence_type_roles.map(&:correspondence_type_id)

            sar_ir_ct_id = CorrespondenceType.sar_internal_review.id
            expect(ctrs_ids).to include(sar_ir_ct_id)
          end

          it "does not add access if SAR access is not present" do
            post :create, params: params_foi_access
            bu = BusinessUnit.last

            ctrs_ids = bu.correspondence_type_roles.map(&:correspondence_type_id)

            sar_ir_ct_id = CorrespondenceType.sar_internal_review.id
            expect(ctrs_ids).not_to include(sar_ir_ct_id)
          end
        end
      end
    end

    context "when signed in as a non-manager" do
      before do
        sign_in foi_responder
      end

      it "redirects to root with unauth message in flash" do
        post :create, params: { "team" => { "name" => "Frog sizing unit" } }
        expect(flash["alert"]).to eq "You are not authorised to add new teams"
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET edit" do
    context "when signed in as a manager" do
      let(:params) { { id: bg.id } }

      before do
        sign_in manager
      end

      it "authorises" do
        expect {
          get :edit, params:
        }.to require_permission(:edit?)
               .with_args(manager, bg)
      end

      it "assigns @team" do
        get(:edit, params:)
        expect(assigns(:team)).to eq bg
      end
    end

    context "when signed in as a non manager" do
      before do
        sign_in foi_responder
      end

      context "and team that the responder ia a member of" do
        let(:params) { { id: business_unit.id } }

        it "authorises" do
          expect {
            get :edit, params:
          }.to require_permission(:edit?)
                 .with_args(foi_responder, business_unit)
        end

        it "assigns @team" do
          get(:edit, params:)
          expect(assigns(:team)).to eq business_unit
        end

        it "renders edit page" do
          get(:edit, params:)
          expect(response).to render_template(:edit)
        end
      end

      context "and team that the repsonder is not a member of" do
        let(:other_bu) { business_unit2 }
        let(:params) { { id: other_bu.id } }

        it "redirects to root path with unauth message" do
          get(:edit, params:)
          expect(flash["alert"]).to eq "You are not authorised to edit this team"
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe "PATCH update", versioning: true do
    context "when logged in as a manager" do
      let(:params) do
        { id: business_unit.id,
          team: {
            name: "New Name",
            email: "n00b@localhost",
            team_lead: "New Team Lead",
          } }
      end

      let(:params_sar_ir_access) do
        { id: business_unit.id,
          team: {
            "name" => "Frog sizing unit",
            "email" => "frogs@a.com",
            "team_lead" => "Stephen Richards",
            "correspondence_type_ids" => [CorrespondenceType.sar.id.to_s],
          } }
      end

      let(:params_foi_access) do
        { id: business_unit.id,
          team: {
            "name" => "Frog sizing unit",
            "email" => "frogs@a.com",
            "team_lead" => "Stephen Richards",
            "correspondence_type_ids" => [CorrespondenceType.foi.id.to_s],
          } }
      end

      before do
        sign_in manager
      end

      context "and SAR IR access" do
        it "adds access if SAR access is enabled" do
          patch :update, params: params_sar_ir_access
          bu = business_unit.reload

          ctrs_ids = bu.correspondence_type_roles.map(&:correspondence_type_id)

          sar_ir_ct_id = CorrespondenceType.sar_internal_review.id
          expect(ctrs_ids).to include(sar_ir_ct_id)
        end

        it "does not add access if SAR access is not present" do
          patch :update, params: params_foi_access
          bu = business_unit.reload

          ctrs_ids = bu.correspondence_type_roles.map(&:correspondence_type_id)

          sar_ir_ct_id = CorrespondenceType.sar_internal_review.id
          expect(ctrs_ids).not_to include(sar_ir_ct_id)
        end
      end

      it "authorises" do
        expect {
          patch :update, params:
        }.to require_permission(:update?)
               .with_args(manager, business_unit)
      end

      it "updates the given team" do
        patch(:update, params:)

        business_unit.reload
        expect(business_unit.name).to  eq "New Name"
        expect(business_unit.email).to eq "n00b@localhost"
        expect(business_unit.team_lead).to eq "New Team Lead"
      end

      it "records the id of the user updating the team" do
        patch(:update, params:)
        whodunnit = business_unit.versions.last.whodunnit.to_i
        expect(whodunnit).to eq manager.id
      end

      context "and redirects to the expected path" do
        it "redirect to areas covered page after updating business unit" do
          patch(:update, params:)
          expect(response).to redirect_to(areas_covered_by_team_path(business_unit.id))
        end

        it "redirects directorates to their parent team" do
          patch :update, params: { id: directorate.id,
                                   team: {
                                     name: "New Name",
                                     email: "n00b@localhost",
                                     team_lead: "New Team Lead",
                                   } }
          expect(flash[:notice]).to eq "Team details updated"
          expect(response).to redirect_to(team_path(directorate.parent_id))
        end

        it "redirects business groups to the team path" do
          patch :update, params: { id: bg.id,
                                   team: {
                                     name: "New Name",
                                     email: "n00b@localhost",
                                     team_lead: "New Team Lead",
                                   } }
          expect(flash[:notice]).to eq "Team details updated"
          expect(response).to redirect_to(teams_path)
        end
      end
    end

    context "when logged in as a non-manager" do
      before do
        sign_in foi_responder
      end

      context "and team that the responder ia a member of" do
        let(:other_bu) { business_unit2 }
        let(:params) do
          {
            "id" => other_bu.id,
            "team" => {
              "name" => "New Frog sizing unit",
              "email" => "frogs@a.com",
              "team_lead" => "Johnny New",
              "parent_id" => directorate.id,
              "role" => "responder",
            },
            "team_type" => "bu",
            "commit" => "Submit",
          }
        end

        it "returns success" do
          patch(:update, params:)
          expect(response).to redirect_to(root_path)
        end

        it "updates the teaam details" do
          patch(:update, params:)
          t = other_bu.reload
          expect(t.name).to eq "SAR Responding Team"
          expect(t.team_lead).to match(/Deputy Director \d+/)
        end
      end
    end
  end

  describe "GET new" do
    context "when logged in as a non manager" do
      before do
        sign_in foi_responder
      end

      it "redirects to root with unauth message in flash" do
        get :new, params: { team_type: "bu" }
        expect(flash["alert"]).to eq "You are not authorised to add new teams"
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET business_areas_covered" do
    let(:params) { { id: business_unit.id } }

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        get :business_areas_covered, params:
      }.to require_permission(:business_areas_covered?)
               .with_args(manager, business_unit)
    end

    it "assigns @team" do
      get(:business_areas_covered, params:)
      expect(assigns(:team)).to eq business_unit
    end

    it "assigns @creating_team" do
      get :business_areas_covered, params:, flash: { "creating_team" => true }
      expect(assigns(:creating_team)).to eq true
    end

    it "renders the business_areas_covered template" do
      get(:business_areas_covered, params:)
      expect(response).to render_template(:business_areas_covered)
    end
  end

  describe "POST create_business_areas_covered" do
    let(:params) do
      {
        id: business_unit.id,
        team_property: {
          "value" => "A new area covered",
        },
      }
    end

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        post :create_business_areas_covered, params:, xhr: true
      }.to require_permission(:business_areas_covered?)
               .with_args(manager, business_unit)
    end

    it "assigns @team" do
      post :create_business_areas_covered, params:, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it "assigns @areas" do
      post :create_business_areas_covered, params:, xhr: true
      expect(assigns(:areas)).to eq business_unit.areas
    end

    it "creates a new area" do
      post :create_business_areas_covered, params:, xhr: true
      expect(business_unit.reload.areas.count).to eq 2
    end

    it "renders the create.js.erb" do
      post :create_business_areas_covered, params:, xhr: true
      expect(response).to render_template("teams/business_areas/create")
    end
  end

  describe "DELETE destroy_business_area" do
    let(:params) do
      {
        id: business_unit.id,
        area_id: business_unit.areas.first.id,
        team_property: {
          "value" => "A new area covered",
        },
      }
    end

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        delete :destroy_business_area, params:, xhr: true
      }.to require_permission(:business_areas_covered?)
               .with_args(manager, business_unit)
    end

    it "assigns @team" do
      delete :destroy_business_area, params:, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it "deletes the area" do
      old_area = business_unit.areas.first
      delete :destroy_business_area, params:, xhr: true
      expect(business_unit.reload.areas).not_to include(old_area)
    end

    it "renders the destroy.js.erb" do
      delete :destroy_business_area, params:, xhr: true
      expect(response).to render_template("teams/business_areas/destroy")
    end
  end

  describe "GET update_business_area_form" do
    let(:params) do
      {
        id: business_unit.id,
        area_id: business_unit.areas.first.id,
        "team_property" => {
          "value" => "This was updated",
        },
      }
    end

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        get :update_business_area_form, params:, xhr: true
      }.to require_permission(:business_areas_covered?)
               .with_args(manager, business_unit)
    end

    it "assigns @team" do
      get :update_business_area_form, params:, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it "renders the get_update_form.js.erb" do
      get :update_business_area_form, params:, xhr: true
      expect(response).to render_template("teams/business_areas/get_update_form")
    end
  end

  describe "PATCH update_business_area" do
    let(:params) do
      {
        id: business_unit.id,
        area_id: business_unit.areas.first.id,
        "team_property" => {
          "value" => "This was updated",
        },
      }
    end

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        patch :update_business_area, params:, xhr: true
      }.to require_permission(:business_areas_covered?)
               .with_args(manager, business_unit)
    end

    it "assigns @team" do
      patch :update_business_area, params:, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it "updates the area" do
      old_area_value = business_unit.areas.first.value
      patch :update_business_area, params:, xhr: true
      expect(business_unit.reload.areas.first.value).not_to eq old_area_value
      expect(business_unit.reload.areas.first.value).to eq "This was updated"
    end

    it "renders the get_update_form.js.erb" do
      patch :update_business_area, params:, xhr: true
      expect(response).to render_template("teams/business_areas/update")
    end
  end

  describe "#move_to_directorate" do
    before do
      sign_in manager
    end

    context "without choosing a business group" do
      let(:params) do
        {
          id: business_unit.id,
        }
      end

      it "authorises" do
        expect {
          get :move_to_directorate, params:
        }.to require_permission(:move?)
                 .with_args(manager, business_unit)
      end

      it "assigns @team" do
        get(:move_to_directorate, params:)
        expect(assigns(:team)).to eq business_unit
      end

      it "renders the right template" do
        get(:move_to_directorate, params:)
        expect(response).to render_template("teams/move_to_directorate")
      end
    end

    context "with a business group selected" do
      let(:params) do
        {
          id: business_unit.id,
          business_group_id: bg.id,
        }
      end

      before do
        find_or_create :deactivated_directorate
      end

      it "assigns @directorates, but not deactivated ones" do
        get(:move_to_directorate, params:)
        expect(assigns(:directorates)).to match_array [directorate]
      end
    end
  end

  describe "GET #move_to_directorate_form" do
    let(:destination_directorate) { find_or_create :directorate, name: "Destination Directorate" }

    before do
      sign_in manager
    end

    context "with a directorate selected" do
      let(:params) do
        {
          id: business_unit.id,
          directorate_id: destination_directorate.id,
        }
      end

      it "assigns @directorate" do
        get(:move_to_directorate_form, params:)
        expect(assigns(:directorate)).to eq destination_directorate
      end

      it "authorises" do
        expect {
          get :move_to_directorate_form, params:
        }.to require_permission(:move?)
                 .with_args(manager, business_unit)
      end

      it "assigns @team" do
        get(:move_to_directorate, params:)
        expect(assigns(:team)).to eq business_unit
      end
    end
  end

  describe "PATCH #update_directorate" do
    let(:destination_directorate) { find_or_create :directorate, name: "Destination Directorate" }
    let(:params) do
      {
        id: business_unit.id,
        directorate_id: destination_directorate.id,
      }
    end

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        patch :update_directorate, params:
      }.to require_permission(:move?)
               .with_args(manager, business_unit)
    end

    it "assigns @team" do
      patch(:update_directorate, params:)
      expect(assigns(:team)).to eq business_unit
    end

    it "redirects away from team" do
      patch(:update_directorate, params:)
      expect(response).to redirect_to(team_path(Team.last))
      expect(response).not_to redirect_to(team_path(business_unit))
      expect(flash[:notice]).to have_content "has been moved to"
    end

    it "updates the area" do
      old_parent = business_unit.parent
      patch(:update_directorate, params:)
      new_business_unit = BusinessUnit.last
      expect(new_business_unit.parent).not_to eq old_parent
      expect(new_business_unit.parent).to eq destination_directorate
    end

    # context 'signed in as a non-manager' do

    #   before(:each) do
    #     sign_in foi_responder
    #   end

    #   it 'redirects to root with unauth message in flash' do
    #     post :create, params:  { 'team' => {  'name' => 'Frog sizing unit' } }
    #     expect(flash['alert']).to eq 'You are not authorised to add new teams'
    #     expect(response).to redirect_to(root_path)
    #   end
    # end
  end

  describe "#move_to_business_group" do
    before do
      sign_in manager
    end

    let(:params) do
      {
        id: directorate.id,
      }
    end

    it "authorises" do
      expect {
        get :move_to_business_group, params:
      }.to require_permission(:move?)
               .with_args(manager, directorate)
    end

    it "assigns @team" do
      get(:move_to_business_group, params:)
      expect(assigns(:team)).to eq directorate
    end

    it "renders the right template" do
      get(:move_to_business_group, params:)
      expect(response).to render_template("teams/move_to_business_group")
    end
  end

  describe "GET #move_to_business_group_form" do
    let(:destination_business_group) { find_or_create :business_group, name: "Destination Business Group" }

    before do
      sign_in manager
    end

    context "with a bussiness group selected" do
      let(:params) do
        {
          id: directorate.id,
          business_group_id: destination_business_group.id,
        }
      end

      it "assigns @directorate" do
        get(:move_to_business_group_form, params:)
        expect(assigns(:business_group)).to eq destination_business_group
      end

      it "authorises" do
        expect {
          get :move_to_business_group_form, params:
        }.to require_permission(:move?)
                 .with_args(manager, directorate)
      end

      it "assigns @team" do
        get(:move_to_business_group_form, params:)
        expect(assigns(:team)).to eq directorate
      end
    end
  end

  describe "PATCH #update_business_group" do
    let(:destination_business_group) { find_or_create :business_group, name: "Destination Business Group" }
    let(:params) do
      {
        id: directorate.id,
        business_group_id: destination_business_group.id,
      }
    end

    before do
      sign_in manager
    end

    it "authorises" do
      expect {
        patch :update_business_group, params:
      }.to require_permission(:move?)
               .with_args(manager, directorate)
    end

    it "assigns @team" do
      patch(:update_business_group, params:)
      expect(assigns(:team)).to eq directorate
    end

    it "redirects away from team" do
      patch(:update_business_group, params:)
      expect(response).not_to redirect_to(team_path(directorate))
      expect(response).to redirect_to(team_path(Directorate.last))
      expect(flash[:notice]).to have_content "has been moved to"
    end

    it "updates the area" do
      old_parent = directorate.parent
      patch(:update_business_group, params:)
      new_directorate = Directorate.last
      expect(new_directorate.parent).not_to eq old_parent
      expect(new_directorate.parent).to eq destination_business_group
    end
  end

  describe "#join_teams" do
    before do
      sign_in manager
    end

    context "without choosing a business group" do
      let(:params) do
        {
          id: business_unit.id,
        }
      end

      it "assigns @team" do
        get(:join_teams, params:)
        expect(assigns(:team)).to eq business_unit
      end

      it "renders the right template" do
        get(:join_teams, params:)
        expect(response).to render_template("teams/join_teams")
      end
    end
  end

  describe "#join_teams_form" do
    before do
      sign_in manager
    end

    context "with a target business unit" do
      let(:target_business_unit) { find_or_create :foi_responding_team }
      let(:params) do
        {
          id: business_unit.id,
          target_team_id: target_business_unit.id,
        }
      end

      it "assigns @team" do
        get(:join_teams_form, params:)
        expect(assigns(:team)).to eq business_unit
      end

      it "assigns @target_team" do
        get(:join_teams_form, params:)
        expect(assigns(:target_team)).to eq target_business_unit
      end

      it "renders the right template" do
        get(:join_teams_form, params:)
        expect(response).to render_template("teams/join_teams_form")
      end
    end
  end

  describe "#active_users" do
    let!(:team) { create :responding_team }
    let!(:user) { team.users.first }

    it "displays active users" do
      expect(team.active_users).to include(user)
    end

    it "does not show deactivated users" do
      user.soft_delete
      expect(team.active_users).not_to include(user)
    end
  end
end
