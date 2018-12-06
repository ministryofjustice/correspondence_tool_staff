require "rails_helper"

describe CasesController do
  let(:manager)        { find_or_create :disclosure_bmt_user }
  let(:responded_case) { create :responded_case,
                                creation_time: 6.business_days.ago }
  let(:date_responded) { 5.business_days.after(responded_case.created_at) }
  let(:params)         { {
                           id: responded_case.id,
                           case_foi: {
                             date_responded_dd: date_responded.day.to_s,
                             date_responded_mm: date_responded.month.to_s,
                             date_responded_yyyy: date_responded.year.to_s,
                           }
                         } }

  describe '#process_date_responded' do
    before do
      sign_in manager
    end

    it 'authorises can_close_case?' do
      expect {
        patch :process_date_responded, params: params
      }.to require_permission(:can_close_case?)
             .with_args(manager, responded_case)
    end

    context 'valid date responded entered' do
      it 'sets the date responded' do
        patch :process_date_responded, params: params

        responded_case.reload
        expect(responded_case.date_responded).to eq date_responded.to_date
      end

      it 'defaults case lateness to responding team' do
        patch :process_date_responded, params: params

        responded_case.reload
        expect(responded_case.late_team).to eq responded_case.responding_team
      end

      it 'redirects to the closure outcomes page' do
        patch :process_date_responded, params: params

        expect(response).to redirect_to(closure_outcomes_case_path(responded_case))
      end
    end
  end
end
