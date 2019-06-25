require 'rails_helper'

RSpec.describe Cases::OverturnedFoiController, type: :controller do
  describe 'closeable' do
    describe '#confirm_respond' do
      let(:case_with_response) { create :case_with_response }
      let(:responder) { case_with_response.responder }
      let(:responding_team) { case_with_response.responding_team }
      let(:ot_foi) {
        create(
          :with_response_ot_ico_foi,
          responder: responder,
          responding_team: responding_team
        )
      }
      let(:date_responded) { ot_foi.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: 'overturned_ico_foi',
          overturned_foi:  {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
          },
          commit: 'Mark response as sent',
          id:  ot_foi.id.to_s
        }
      end

      context 'as the assigned responder' do
        before { sign_in responder }

        it 'transitions current_state to "responded"' do
          stub_find_case(ot_foi.id) do |kase|
            expect(kase).to receive(:respond).with(responder)
          end
          patch :confirm_respond, params: params
        end

        it 'redirects to the case list view' do
          expect(patch :confirm_respond, params: params).
            to redirect_to(case_path(ot_foi))
        end

        context 'with invalid params' do
          let(:params) do
            {
              correspondence_type: 'overturned_ico_foi',
              overturned_foi:  {
                date_responded_dd: '',
                date_responded_mm: '',
                date_responded_yyyy: '',
              },
              commit: 'Mark response as sent',
              id:  ot_foi.id.to_s
            }
          end
          it 'redirects to the respond page' do
            expect(patch :confirm_respond, params: params)
            expect(response).to render_template(:respond)
          end
        end
      end
    end
  end
end
