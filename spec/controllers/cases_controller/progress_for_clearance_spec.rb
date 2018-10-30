require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:responder)           { create :responder }
  let(:responding_team)     { responder.teams.first}
  let(:accepted_sar)        { create :accepted_sar,
                                     :flagged_accepted,
                                     :dacu_disclosure,
                                     responder: responder  }
  let(:disclosure_team)     { accepted_sar.approving_teams.first }

  describe 'PATCH progress_for_clearance' do
    before do
      sign_in responder
    end

    it 'authorizes' do
      expect {
        patch :progress_for_clearance, params: { id: accepted_sar.id }
      } .to require_permission(:progress_for_clearance?)
              .with_args(responder, accepted_sar)
    end

    it 'sets @case' do
      patch :progress_for_clearance, params: { id: accepted_sar.id }
      expect(assigns(:case)).to eq accepted_sar
    end

    it 'flashes a notification' do
      patch :progress_for_clearance, params: { id: accepted_sar.id }
      expect(flash[:notice])
        .to eq 'The Disclosure team has been notified this case is ready for clearance'
    end

    it 'redirects to case details page' do
      patch :progress_for_clearance, params: { id: accepted_sar.id }
      expect(response).to redirect_to(case_path(accepted_sar))
    end

    it 'calls the state_machine method' do

      patch :progress_for_clearance, params: { id: accepted_sar.id }

      stub_find_case(accepted_sar.id) do |kase|
        expect(kase.state_machine).to have_received(:progress_for_clearance!)
        .with(acting_user: responder,
             acting_team: responding_team,
             target_team: disclosure_team )

      end
    end
  end
end
