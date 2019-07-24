require 'rails_helper'

RSpec.describe Cases::ClearancesController, type: :controller do
  let(:responder)             { find_or_create :foi_responder }
  let(:responding_team)       { responder.responding_teams.first }
  let(:manager)               { find_or_create :disclosure_specialist_bmt }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }

  let!(:assigned_case) {
    create :assigned_case, responding_team: responding_team
  }

  describe '#flag_for_clearance' do
    let!(:service) do
      double(CaseFlagForClearanceService, call: true).tap do |svc|
        allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
      end
    end

    let(:unflagged_case_decorated) do
      assigned_case.decorate.tap do |decorated|
        allow(assigned_case).to receive(:decorate).and_return(decorated)
      end
    end

    let(:params) {{ case_id: assigned_case.id }}

    context 'as an anonymous user' do
      it 'redirects to sign_in' do
        expect(patch :flag_for_clearance, params: params)
          .to redirect_to(new_user_session_path)
      end

      context 'calling the action from an AJAX request' do
        it 'does not call the service' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(CaseFlagForClearanceService).not_to have_received(:new)
        end

        it 'returns an error' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_http_status 401
        end
      end
    end

    context 'as an authenticated responder' do
      before do
        sign_in responder
      end

      it 'does not call the service' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(CaseFlagForClearanceService).not_to have_received(:new)
      end

      it 'redirects to the application root path' do
        patch :flag_for_clearance, params: params, xhr: true
        expect(response.body)
          .to include 'Turbolinks.visit("http://test.host/", {"action":"replace"})'
      end
    end

    context 'as an authenticated manager' do
      before do
        sign_in manager
      end

      context 'calling the action from an AJAX request' do
        it 'instantiates and calls the service' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(CaseFlagForClearanceService)
            .to have_received(:new).with(
              user: manager,
              kase: unflagged_case_decorated,
              team: BusinessUnit.dacu_disclosure
            )
          expect(service).to have_received(:call)
        end

        it 'renders the view' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_rendered('flag_for_clearance.js.erb')
        end

        it 'returns a success code' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_http_status 200
        end
      end

      context 'calling the action from a HTTP request' do
        it 'instantiates and calls the service' do
          patch :flag_for_clearance, params: params
          expect(CaseFlagForClearanceService)
            .to have_received(:new).with(
              user: manager,
              kase: unflagged_case_decorated,
              team: BusinessUnit.dacu_disclosure
            )
          expect(service).to have_received(:call)
        end

        it 'renders the view' do
          patch :flag_for_clearance, params: params
          expect(response).to redirect_to(case_path(unflagged_case_decorated))
        end

        it 'returns a success code' do
          patch :flag_for_clearance, params: params
          expect(response).to have_http_status 302
        end
      end
    end

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      context 'calls the action from an AJAX request' do
        it 'instantiates and calls the service' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(CaseFlagForClearanceService)
            .to have_received(:new).with(
              user: disclosure_specialist,
              kase: unflagged_case_decorated,
              team: BusinessUnit.dacu_disclosure
            )
          expect(service).to have_received(:call)
        end

        it 'renders the view' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_rendered('flag_for_clearance.js.erb')
        end

        it 'returns success' do
          patch :flag_for_clearance, params: params, xhr: true
          expect(response).to have_http_status 200
        end
      end

      context 'calls the action from a HTTP request' do
        it 'instantiates and calls the service' do
          patch :flag_for_clearance, params: params
          expect(CaseFlagForClearanceService)
            .to have_received(:new).with(
              user: disclosure_specialist,
              kase: unflagged_case_decorated,
              team: BusinessUnit.dacu_disclosure
            )
          expect(service).to have_received(:call)
        end

        it 'renders the view' do
          patch :flag_for_clearance, params: params
          expect(response).to redirect_to case_path(unflagged_case_decorated)
        end

        it 'returns success' do
          patch :flag_for_clearance, params: params
          expect(response).to have_http_status 302
        end
      end
    end
  end

  describe '#progress_for_clearance' do
    let(:accepted_sar)     { create :accepted_sar, :flagged_accepted }
    let(:responder)        { accepted_sar.responder }
    let(:responding_team)  { accepted_sar.responding_team }
    let(:disclosure_team)  { accepted_sar.approving_teams.first }
    let(:params) {{ case_id: accepted_sar.id }}

    context 'assigned responder' do
      before do
        sign_in responder
      end

      it 'authorizes' do
        expect {
          patch :progress_for_clearance, params: params
        }.to require_permission(:progress_for_clearance?)
          .with_args(responder, accepted_sar)
      end

      it 'sets @case' do
        patch :progress_for_clearance, params: params
        expect(assigns(:case)).to eq accepted_sar
      end

      it 'flashes a notification' do
        patch :progress_for_clearance, params: params
        expect(flash[:notice])
          .to eq 'The Disclosure team has been notified this case is ready for clearance'
      end

      it 'redirects to case details page' do
        patch :progress_for_clearance, params: params
        expect(response).to redirect_to(case_path(accepted_sar))
      end

      it 'calls the state_machine method' do

        patch :progress_for_clearance, params: params

        stub_find_case(accepted_sar.id) do |kase|
          expect(kase.state_machine).to have_received(:progress_for_clearance!)
            .with(
              acting_user: responder,
              acting_team: responding_team,
              target_team: disclosure_team
            )
        end
      end
    end

    context 'responder in assigner team' do
      let(:another_assigned_responder)  {
        create :responder, responding_teams: [responding_team]
      }

      before do
        sign_in another_assigned_responder
      end

      it 'authorizes' do
        expect {
          patch :progress_for_clearance, params: params
        }.to require_permission(:progress_for_clearance?)
          .with_args(another_assigned_responder, accepted_sar)
      end

      it 'calls the state_machine method' do
        patch :progress_for_clearance, params: params

        stub_find_case(accepted_sar.id) do |kase|
          expect(kase.state_machine)
            .to have_received(:progress_for_clearance!).with(
              acting_user: another_assigned_responder,
              acting_team: responding_team,
              target_team: disclosure_team
            )
        end
      end
    end
  end

  describe '#request_further_clearance' do
    let(:service) {
      instance_double(RequestFurtherClearanceService, call: :ok)
    }

    context 'FOI' do
      let(:accepted_case) { create :accepted_case }
      let(:params) {{ case_id: accepted_case.id }}

      before do
        sign_in manager
        allow(RequestFurtherClearanceService).to receive(:new).and_return(service)
      end

      it 'authorizes' do
        expect {
          patch :request_further_clearance, params: params
        }.to require_permission(:request_further_clearance?)
          .with_args(manager, accepted_case)
      end

      it 'sets @case' do
        patch :request_further_clearance, params: params
        expect(assigns(:case)).to eq accepted_case
      end

      it 'calls the Request further clearance service' do
        patch :request_further_clearance, params: params
        expect(RequestFurtherClearanceService).to have_received(:new)
          .with(hash_including(user: manager,
            kase: accepted_case))

        expect(service).to have_received(:call)
      end

      it 'flashes a notification' do
        patch :request_further_clearance, params: params
        expect(flash[:notice])
          .to eq 'Further clearance requested'
      end

      it 'redirects to case details page' do
        patch :request_further_clearance, params: params
        expect(response).to redirect_to(case_path(accepted_case))
      end
    end

    context 'SAR' do
      let(:accepted_sar) { create :accepted_sar }
      let(:params) {{ case_id: accepted_sar.id }}

      before do
        sign_in manager
        allow(RequestFurtherClearanceService).to receive(:new).and_return(service)
      end

      it 'authorizes' do
        expect {
          patch :request_further_clearance, params: params
        }.to require_permission(:request_further_clearance?)
          .with_args(manager, accepted_sar)
      end

      it 'sets @case' do
        patch :request_further_clearance, params: params
        expect(assigns(:case)).to eq accepted_sar
      end

      it 'calls the Request further clearance service' do
        patch :request_further_clearance, params: params
        expect(RequestFurtherClearanceService).to have_received(:new)
          .with(hash_including(user: manager,
            kase: accepted_sar))

        expect(service).to have_received(:call)
      end

      it 'flashes a notification' do
        patch :request_further_clearance, params: params
        expect(flash[:notice])
          .to eq 'Further clearance requested'
      end

      it 'redirects to case details page' do
        patch :request_further_clearance, params: params
        expect(response).to redirect_to(case_path(accepted_sar))
      end
    end
  end

  describe '#unflag_taken_on_case_for_clearance' do
    let!(:service) { double(CaseUnflagForClearanceService) }
    let(:params) {{ case_id: flagged_case.id, message: 'message' }}
    let(:flagged_case) {
      create(
        :accepted_case,
        :flagged,
        responding_team: responding_team,
        approving_team: dacu_disclosure
      )
    }

    context 'as an authenticated disclosure_specialist' do
      before do
        sign_in disclosure_specialist
      end

      it 'authorises' do
        expect {
          patch :unflag_taken_on_case_for_clearance, params: params
        }.to require_permission(:unflag_for_clearance?)
          .with_args(disclosure_specialist, flagged_case)
      end

      it 'redirects to case list' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(response).to redirect_to(case_path(flagged_case))
      end

      it 'displays a flash notice' do
        patch :unflag_taken_on_case_for_clearance, params: params
        expect(flash[:notice]).to eq 'Clearance removed for this case.'
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

      let(:params) {{ case_id: flagged_case.id }}

      context 'as an authenticated disclosure_specialist' do
        before do
          sign_in disclosure_specialist
        end

        context 'calling the action from an AJAX request' do
          it 'authorises' do
            expect {
              patch :unflag_for_clearance, params: params, xhr: true
            }.to require_permission(:unflag_for_clearance?)
              .with_args(disclosure_specialist, flagged_case)
          end

          it 'instantiates and calls the service' do
            patch :unflag_for_clearance, params: params, xhr: true
            expect(CaseUnflagForClearanceService)
              .to have_received(:new).with(
                user: disclosure_specialist,
                kase: flagged_case_decorated,
                team: BusinessUnit.dacu_disclosure,
                message: nil
              )
            expect(service).to have_received(:call)
          end

          it 'renders the view' do
            patch :unflag_for_clearance, params: params, xhr: true
            expect(response).to have_rendered(('unflag_for_clearance.js.erb'))
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
            }.to require_permission(:unflag_for_clearance?)
              .with_args(disclosure_specialist, flagged_case)
          end

          it 'instantiates and calls the service' do
            patch :unflag_for_clearance, params: params
            expect(CaseUnflagForClearanceService)
              .to have_received(:new).with(
                user: disclosure_specialist,
                kase: flagged_case_decorated,
                team: BusinessUnit.dacu_disclosure,
                message: nil
              )
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
