require 'rails_helper'
describe CasesController, type: :controller do

  describe 'PATCH confirm_respond' do
    let(:responder)          { case_with_response.responder }
    let(:responding_team)    { case_with_response.responding_team }
    let(:another_responder)  { create :responder }
    let(:manager)            { find_or_create :disclosure_bmt_user }
    let(:approver)           { find_or_create :disclosure_specialist }

    let(:case_with_response) { create :case_with_response }
    let(:ot_foi)             { create :with_response_ot_ico_foi,
                                      responder: responder,
                                      responding_team: responding_team }
    let(:approved_ico)       { create :approved_ico_foi_case }


    context 'FOI case' do
      let(:date_responded)     { case_with_response.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: 'foi',
          case_foi:  {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
          },
          commit: 'Mark response as sent',
          id:  case_with_response.id.to_s
        }
      end


      context 'as an anonymous user' do
        it 'redirects to sign_in' do
          expect(patch :confirm_respond, params: params).
            to redirect_to(new_user_session_path)
        end

        it 'does not transition current_state' do
          expect(case_with_response.current_state).to eq 'awaiting_dispatch'
          patch :confirm_respond, params: params
          expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        end
      end

      context 'as an authenticated manager' do

        before { sign_in manager }

        it 'redirects to the application root' do
          expect(patch :confirm_respond, params: params).
              to redirect_to(manager_root_path)
        end

        it 'does not transition current_state' do
          expect(case_with_response.current_state).to eq 'awaiting_dispatch'
          patch :confirm_respond, params: params
          expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        end
      end

      context 'as the assigned responder' do

        before { sign_in responder }

        it 'transitions current_state to "responded"' do
          stub_find_case(case_with_response.id) do |kase|
            expect(kase).to receive(:respond).with(responder)
          end
          patch :confirm_respond, params: params
        end

        it 'redirects to the case list view' do
          expect(patch :confirm_respond, params: params).
              to redirect_to(case_path(case_with_response))
        end

        context 'with invalid params' do
          let(:params) do
            {
              correspondence_type: 'foi',
              case_foi:  {
                date_responded_dd: '',
                date_responded_mm: '',
                date_responded_yyyy: '',
              },
              commit: 'Mark response as sent',
              id:  case_with_response.id.to_s
            }
          end
          it 'redirects to the respond page' do
            expect(patch :confirm_respond, params: params)
            expect(response).to render_template(:respond)
          end
        end
      end

      context 'as another responder' do
        before { sign_in another_responder }

        it 'redirects to the application root' do
          expect(patch :confirm_respond, params: params).
                to redirect_to(responder_root_path)
        end

        it 'does not transition current_state' do
          expect(case_with_response.current_state).to eq 'awaiting_dispatch'
          patch :confirm_respond, params: params
          expect(case_with_response.current_state).to eq 'awaiting_dispatch'
        end
      end
    end

    context 'Overturned ICO FOI case' do
      let(:date_responded)     { ot_foi.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: 'overturned_ico_foi',
          case_overturned_foi:  {
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
              case_overturned_foi:  {
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


    context 'for ICO cases' do
      let(:date_responded)  { approved_ico.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: 'ico',
          case_ico:  {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
          },
          commit: 'Submit',
          id:  approved_ico.id.to_s
        }
      end

      context 'as the assigned approver' do

        before { sign_in approver }

        it 'transitions current_state to "responded"' do
          stub_find_case(approved_ico.id) do |kase|
            expect(kase).to receive(:respond).with(approver)
          end
          patch :confirm_respond, params: params
        end

        it 'redirects to the case list view' do
          expect(patch :confirm_respond, params: params).
            to redirect_to(case_path(approved_ico))
        end
      end
    end
  end
end
