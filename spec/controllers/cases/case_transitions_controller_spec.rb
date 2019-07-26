require 'rails_helper'

RSpec.describe Cases::CaseTransitionsController, type: :controller do
  describe "#mark_as_waiting_for_data" do
    before do
      sign_in manager
    end
    let(:manager) { find_or_create :branston_user }
    let(:offender_sar) { create(:offender_sar_case).decorate }
    let(:params) {{ id: offender_sar.id }}

    it 'sets @case' do
      patch :mark_as_waiting_for_data, params: params

      expect(assigns(:case)).to eq offender_sar
    end

    it 'authorizes' do
      expect {
        patch :mark_as_waiting_for_data, params: params
      }.to require_permission(:mark_as_waiting_for_data?)
        .with_args(manager, offender_sar)
    end

    it 'flashes a notification' do
      patch :mark_as_waiting_for_data, params: params
      expect(flash[:notice])
        .to eq 'Case updated'
    end

    it 'redirects to case details page' do
      patch :mark_as_waiting_for_data, params: params
      expect(response).to redirect_to(case_path(offender_sar))
    end
  end
end
