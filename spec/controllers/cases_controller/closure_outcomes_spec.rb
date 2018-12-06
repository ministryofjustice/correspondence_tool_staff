require "rails_helper"

describe CasesController do
  let(:manager)        { find_or_create :disclosure_bmt_user }
  let(:responded_case) { create :responded_case }

  describe '#closure_outcomes' do
    before do
      sign_in manager
    end

    it 'authorises' do
      expect {
        get :closure_outcomes, params: { id: responded_case.id }
      }.to require_permission(:can_close_case?)
             .with_args(manager, responded_case)
    end

    it 'renders closure_outcomes.html.slim' do
      get :closure_outcomes, params: { id: responded_case.id }
      expect(response).to render_template(:closure_outcomes)
    end
  end
end
