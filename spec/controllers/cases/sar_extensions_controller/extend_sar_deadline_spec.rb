require "rails_helper"

describe Cases::SarExtensionsController, type: :controller do
  let(:sar_case)          { create :sar_case }
  let(:extended_sar_case) { create :approved_sar, :extended_deadline_sar }
  let(:manager)           { find_or_create :disclosure_bmt_user }

  before do
    sign_in manager
  end

  describe '#new' do
    it 'authorizes' do
      expect {
        get :new, params: {
          case_id: sar_case.id
        }
      }.to require_permission(:extend_sar_deadline?).with_args(manager, sar_case)
      expect(assigns(:case)).to be_a CaseExtendSARDeadlineDecorator
    end
  end
end
