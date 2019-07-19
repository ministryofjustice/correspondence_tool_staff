require 'rails_helper'

RSpec.describe Cases::CaseTransitionsController, type: :controller do
  describe "#create" do
    before do
      sign_in manager
    end
    let(:manager) { find_or_create :branston_user }
    let(:offender_sar) { create(:offender_sar_case).decorate }
    let(:params) {{ case_id: offender_sar.id }}

    it 'sets @case' do
      post :create, params: params

      expect(assigns(:case)).to eq offender_sar
    end

    # it 'authorizes' do
    #   expect {
    #     post :create, params: params
    #   }.to require_permission(:create_case_transition?)
    #     .with_args(manager, offender_sar)
    # end

    # it 'flashes a notification' do
    #   patch :progress_for_clearance, params: params
    #   expect(flash[:notice])
    #     .to eq 'The Disclosure team has been notified this case is ready for clearance'
    # end

    # it 'redirects to case details page' do
    #   patch :progress_for_clearance, params: params
    #   expect(response).to redirect_to(case_path(accepted_sar))
    # end

    # it 'calls the state_machine method' do

    #   patch :progress_for_clearance, params: params

    #   stub_find_case(accepted_sar.id) do |kase|
    #     expect(kase.state_machine).to have_received(:progress_for_clearance!)
    #       .with(
    #         acting_user: responder,
    #         acting_team: responding_team,
    #         target_team: disclosure_team
    #       )
    #   end
    # end

  end
end
