require "rails_helper"

describe CasesController, type: :controller do
  let(:sar_case)  { create :sar_case }
  let(:manager)   { find_or_create :disclosure_bmt_user}

  before do
    sign_in manager
  end

  describe 'GET extend_deadline_for_sar' do
    it 'authorizes' do
      expect { get :extend_deadline_for_sar, params: { id: sar_case.id } }
        .to require_permission(:extend_deadline_for_sar?)
              .with_args(manager, sar_case)
    end
  end
end
