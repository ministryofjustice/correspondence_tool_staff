require 'rails_helper'

RSpec.describe CasesController, type: :controller do

  let(:approver)            { approving_team.users.first }
  let(:approving_team)      { approved_ico.approving_teams.first }
  let(:approved_ico)        { create :approved_ico_foi_case, :flagged_accepted }

  describe 'PATCH record_late_team' do
    context 'assigned approver' do
      before do
        sign_in approver
      end

      it 'authorizes' do
        expect {
          patch :record_late_team, params: { id: approved_ico.id }
        } .to require_permission(:can_respond?)
                .with_args(approver, approved_ico)
      end

      it 'sets @case' do
        patch :record_late_team, params: { id: approved_ico.id }
        expect(assigns(:case)).to eq approved_ico
      end

      it 'redirects to case details page' do
        patch :record_late_team, params: { id: approved_ico.id }
        expect(response).to redirect_to(case_path(approved_ico))
      end

      it 'calls the state_machine method' do

        patch :record_late_team, params: { id: approved_ico.id }

        stub_find_case(approved_ico.id) do |kase|
          expect(kase.state_machine).to have_received(:respond!)
          .with(acting_user: approver,
               acting_team: approving_team)
        end
      end

      it 'sets the late team' do
        patch :record_late_team, params: { case_ico: {late_team_id: approving_team.id }, id: approved_ico.id }
        approved_ico.reload
        expect(approved_ico.late_team_id).to eq approving_team.id
      end
    end
  end
end
