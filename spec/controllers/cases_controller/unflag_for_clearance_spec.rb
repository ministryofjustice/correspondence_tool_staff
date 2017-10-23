require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let!(:service)              {double(CaseUnflagForClearanceService)}
  let(:params)                { { id: flagged_case.id, message: "message"} }
  let(:manager)               { create :manager }
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:flagged_case)          { create :assigned_case, :flagged,
                                    responding_team: responding_team,
                                    approving_team: team_dacu_disclosure }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:responder)            { create :responder }
  let(:responding_team)      { responder.responding_teams.first }
  describe 'PATCH unflag_taken_on_case_for_clearance' do

    context 'as an authenticated responder' do
      before do
        sign_in responder
      end
      it 'flashes an alert to the user' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(flash['alert']).to eq 'You are not authorised to remove clearance from this case'
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'renders the view' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(response).to redirect_to(cases_path)
      end

      it 'displays a flash notice' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(flash[:notice]).to eq "Clearance removed for case #{flagged_case.number}"
      end
    end

    context 'as an authenicated manager' do
      before do
        sign_in manager
      end

      it 'renders the view' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(response).to redirect_to(cases_path)
      end

      it 'displays a flash notice' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(flash[:notice]).to eq "Clearance removed for case #{flagged_case.number}"
      end
    end
  end
  describe 'PATCH unflag_for_clearance' do
    let!(:service) do
      double(CaseUnflagForClearanceService, call: true).tap do |svc|
      allow(CaseUnflagForClearanceService).to receive(:new).and_return(svc)
      end
    end

    let(:flagged_case_decorated) do
      flagged_case.decorate.tap do |decorated|
        allow(flagged_case).to receive(:decorate).and_return(decorated)
      end
    end

    let(:params) { { id: flagged_case.id} }

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(patch :unflag_for_clearance, params: params)
          .to redirect_to(new_user_session_path)
      end

      it 'does not call the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService).not_to have_received(:new)
      end

      it 'returns an error' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 401
      end
    end

    context 'as an authenticated responder' do
      before do
        sign_in responder
      end

      it 'does not call the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService).not_to have_received(:new)
      end

      it 'redirects to the application root path' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response.body)
          .to include 'Turbolinks.visit("http://test.host/", {"action":"replace"})'
      end
    end

    context 'as an authenticated manager' do
      before do
        sign_in manager
      end

      it 'instantiates and calls the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService)
          .to have_received(:new).with(user: manager,
                                       kase: flagged_case_decorated,
                                       team: BusinessUnit.dacu_disclosure,
                                       message: nil)
        expect(service).to have_received(:call)
      end

      it 'renders the view' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_rendered(:unflag_for_clearance)
      end

      it 'returns a success code' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 200
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'instantiates and calls the service' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(CaseUnflagForClearanceService)
          .to have_received(:new).with(user: disclosure_specialist,
                                       kase: flagged_case_decorated,
                                       team: BusinessUnit.dacu_disclosure,
                                       message: nil)
        expect(service).to have_received(:call)
      end

      it 'renders the view' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_rendered(:unflag_for_clearance)
      end

      it 'returns success' do
        patch :unflag_for_clearance, params: params, xhr: true
        expect(response).to have_http_status 200
        expect(response).to have_rendered(:unflag_for_clearance)
      end
    end
  end
end
