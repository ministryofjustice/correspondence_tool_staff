require "rails_helper"

describe Cases::SarExtensionsController, type: :controller do
  let(:extended_sar_case) { create :approved_sar, :extended_deadline_sar }
  let(:manager)           { find_or_create :disclosure_bmt_user }

  before do
    sign_in manager
  end

  describe '#destroy' do
    it 'authorizes' do
      expect {
        delete :destroy,
        params: {
          case_id: extended_sar_case.id
        }
      }.to require_permission(:remove_sar_deadline_extension?).with_args(
        manager,
        extended_sar_case
      )
    end
  end
end
