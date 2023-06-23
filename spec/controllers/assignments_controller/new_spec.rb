require "rails_helper"

RSpec.describe AssignmentsController, type: :controller do # rubocop:disable RSpec/FilePath
  let(:responding_team_1)   { create :responding_team }
  let(:responding_team_2)   { create :responding_team }
  let(:responding_team_3)   { create :responding_team }
  let(:foi_responding_team) { find_or_create :foi_responding_team }
  let(:sar_responding_team) { find_or_create :sar_responding_team }
  let(:manager)             { create :manager }
  let(:unassigned_case)     { create :case }
  let(:params)              { { case_id: unassigned_case.id } }

  describe "GET new" do
    before { sign_in manager }

    it "authorises" do
      expect {
        get :new, params:, flash: { "creating_case" => true }
      }.to require_permission(:can_assign_case?).with_args(manager, unassigned_case)
    end

    it "renders the page for assignment" do
      get :new, params:, flash: { "creating_case" => true }
      expect(response).to render_template(:new)
    end

    it "sets @case" do
      get :new, params:, flash: { "creating_case" => true }
      expect(assigns(:case)).to eq unassigned_case
    end

    it "sets @assignment" do
      get :new, params:, flash: { "creating_case" => true }
      expect(assigns(:assignment)).not_to be_nil
    end

    describe "@business_units" do
      it "is a list business units for a selected business group" do
        params[:business_group_id] = responding_team_1.business_group.id
        get :new, params:, flash: { "creating_case" => true }
        expect(assigns(:business_units)).to match_array [responding_team_1]
      end

      it "is a list of all business units which are responders for the case type in question" do
        params[:show_all] = true
        get :new, params:, flash: { "creating_case" => true }
        expect(assigns(:business_units)).to match_array([foi_responding_team, sar_responding_team])
      end

      it "is not set if no params are used" do
        get :new, params:, flash: { "creating_case" => true }
        expect(assigns(:business_units)).not_to be_present
      end
    end

    it "sets @creating_case" do
      get :new, params:, flash: { "creating_case" => true }
      expect(assigns(:creating_case)).to eq true
    end
  end
end
