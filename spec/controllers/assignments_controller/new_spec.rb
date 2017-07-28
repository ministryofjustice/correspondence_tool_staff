require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:responding_team_1) { create :responding_team }
  let(:responding_team_2) { create :responding_team }
  let(:responding_team_3) { create :responding_team }
  let(:manager)           { create :manager }
  let(:unassigned_case)   { create :case }
  let(:params)            { { case_id: unassigned_case.id } }


  describe 'GET new' do
    before { sign_in manager }

    it 'authorises' do
      expect{
        get :new, params: params, flash:{"creating_case"=> true}
      }.to require_permission(:can_assign_case?)
               .with_args(manager, unassigned_case)
    end

    it 'renders the page for assignment' do
      get :new, params: params, flash:{"creating_case"=> true}
      expect(response).to render_template(:new)
    end

    it 'sets @case' do
      get :new, params: params, flash:{"creating_case"=> true}
      expect( assigns(:case))
          .to eq unassigned_case
    end

    it 'sets @assignment' do
      get :new, params: params, flash:{"creating_case"=> true}
      expect( assigns(:assignment))
          .not_to be_nil
    end

    it 'sets @business_units' do
      get :new, params: params, flash:{"creating_case"=> true}
      expect( assigns(:business_units))
          .to eq [responding_team_1, responding_team_2, responding_team_3]
    end

    it 'sets @creating_case' do
      get :new, params: params, flash:{"creating_case"=> true}
      expect( assigns(:creating_case))
          .to eq true
    end

  end
end
