require 'rails_helper'

RSpec.shared_examples 'edit offender sar spec' do |offender_sar_case, method|
  describe "mark methods" do
    before do
      sign_in manager
    end
    let(:manager) { find_or_create :branston_user }
    let(:offender_sar) { create(offender_sar_case).decorate }
    let(:params) {{ id: offender_sar.id }}

    it 'sets @case' do
      patch method, params: params

      expect(assigns(:case)).to eq offender_sar
    end

    it 'authorizes' do
      expect {
        patch method, params: params
      }.to require_permission("#{method}?")
        .with_args(manager, offender_sar)
    end

    it 'flashes a notification' do
      patch method, params: params
      expect(flash[:notice])
        .to eq 'Case updated'
    end

    it 'redirects to case details page' do
      patch method, params: params
      expect(response).to redirect_to(case_path(offender_sar))
    end
  end
end
