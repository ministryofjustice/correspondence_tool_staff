require "rails_helper"

describe CasesController, type: :controller do
  describe 'GET destroy_case' do
    let(:manager)           { create :manager }
    let(:unassigned_case)   { create :case }
    let(:params)            { { id: unassigned_case.id } }

    before { sign_in manager }

    it 'authorises' do
      expect{
        delete :destroy, params: params
      }.to require_permission(:destroy?)
               .with_args(manager, unassigned_case)
    end

    it 'sets @case' do
      delete :destroy, params: params
      expect(assigns(:case)).to eq unassigned_case
    end

    it 'marks the case as deleted' do
      delete :destroy, params: params
      unassigned_case.reload
      expect(unassigned_case.deleted?).to be true
    end
  end
end
