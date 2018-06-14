require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:responder)           { create :responder }
  let(:accepted_sar)        { create :accepted_sar, :flagged_accepted_sar, responder: responder  }

  describe 'PATCH progress_for_clearance' do
    before do
      sign_in responder
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
  end
end
