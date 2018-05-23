require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let!(:service)              {double(CaseUnflagForClearanceService)}
  let(:params)                { { id: flagged_case.id, message: "message"} }
  let(:manager)               { create :manager }
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:flagged_case)          { create :accepted_case, :flagged,
                                    responding_team: responding_team,
                                    approving_team: team_dacu_disclosure }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:responder)            { create :responder }
  let(:responding_team)      { responder.responding_teams.first }
  describe 'PATCH unflag_taken_on_case_for_clearance' do

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'authorises' do
        expect {
          patch :unflag_taken_on_case_for_clearance, params: params
        } .to require_permission(:unflag_for_clearance?)
                .with_args(disclosure_specialist, flagged_case)
      end

      it 'redirects to case list' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(response).to redirect_to(case_path(flagged_case))
      end

      it 'displays a flash notice' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(flash[:notice]).to eq "Clearance removed for this case."
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

      context 'as an authenticated disclosure_specialist' do
        before do
          sign_in disclosure_specialist
        end

        context 'calling the action from an AJAX request' do
          it 'authorises' do
            expect {
              patch :unflag_for_clearance, params: params, xhr: true
            } .to require_permission(:unflag_for_clearance?)
                    .with_args(disclosure_specialist, flagged_case)
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
            expect(response).to have_rendered(('cases/unflag_for_clearance.js.erb'))
          end

          it 'returns success' do
            patch :unflag_for_clearance, params: params, xhr: true
            expect(response).to have_http_status 200
          end
        end

        context 'calling the action from a HTTP request' do
          it 'authorises' do
            expect {
              patch :unflag_for_clearance, params: params
            } .to require_permission(:unflag_for_clearance?)
                    .with_args(disclosure_specialist, flagged_case)
          end

          it 'instantiates and calls the service' do
            patch :unflag_for_clearance, params: params
            expect(CaseUnflagForClearanceService)
              .to have_received(:new).with(user: disclosure_specialist,
                                           kase: flagged_case_decorated,
                                           team: BusinessUnit.dacu_disclosure,
                                           message: nil)
            expect(service).to have_received(:call)
          end

          it 'renders the view' do
            patch :unflag_for_clearance, params: params
            expect(response).to redirect_to(case_path(flagged_case_decorated))
          end

          it 'returns 200 status' do
            patch :unflag_for_clearance, params: params
            expect(response).to have_http_status 302
          end
        end
      end
    end
  end
end
