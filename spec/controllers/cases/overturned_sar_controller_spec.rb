require 'rails_helper'

RSpec.describe Cases::OverturnedSarController, type: :controller do
  let(:manager) { find_or_create :disclosure_specialist_bmt }
  let(:approver) { create :approver }
  let(:ico_sar) { create :ico_sar_case }
  let(:sar) { create :sar_case }
  let(:overturned_ico_case) { create :overturned_ico_sar }

  context 'logged in as manager' do
    before { sign_in manager }

    context 'valid params' do
      before do
        service = double(NewOverturnedIcoCaseService,
          call: nil,
          error?: false,
          success?: true,
          original_ico_appeal: ico_sar,
          original_case: sar,
          overturned_ico_case: overturned_ico_case)
        params = ActionController::Parameters.new({ id: ico_sar.id })
        expect(NewOverturnedIcoCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)
        #get :new_overturned_ico, params: params.to_unsafe_hash
        get :new, params: params.to_unsafe_hash
      end

      it 'is success' do
        expect(response).to be_success
      end

      it 'assigns a new overturned case to @case' do
        expect(assigns(:case)).to eq overturned_ico_case
      end

      it 'renders the new overturned ico case page' do
        expect(response).to render_template('cases/overturned_sar/new')
      end
    end

    context 'invalid params' do
      before do
        service = double(NewOverturnedIcoCaseService,
          call: nil,
          error?: true,
          success?: false,
          original_ico_appeal: ico_sar,
          original_case: sar,
          overturned_ico_case: overturned_ico_case)
        params = ActionController::Parameters.new({ id: ico_sar.id })
        expect(NewOverturnedIcoCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)
        get :new, params: params.to_unsafe_hash
      end

      it 'is bad_request' do
        expect(response).to be_bad_request
      end

      it 'assigns the original ico appeal to @case' do
        expect(assigns(:case)).to eq ico_sar
      end

      it 'renders the show page for the ico appeal' do
        expect(response).to render_template('cases/show')
      end
    end
  end

  context 'closeable' do
    before(:all)   do
      @responder = find_or_create :sar_responder
      @drafting_ovt_sar_case = create :accepted_ot_ico_sar, responder: @responder
    end

    after(:all) { DbHousekeeping.clean }

    describe '#respond_and_close' do
      let(:params) { {id: @drafting_ovt_sar_case.id.to_s} }

      context 'authorization' do
        it 'does not authorize managers' do
          sign_in manager
          get :respond_and_close, params: params
          expect(flash[:alert]).to eq 'You are not authorised to close this case'
          expect(response).to redirect_to root_path
        end

        it 'authorizes responders' do
          sign_in @responder
          get :respond_and_close, params: params
          expect(flash[:alert]).to be_nil
          expect(response).to be_success
        end

        it 'does not authorize approvers' do
          sign_in approver
          get :respond_and_close, params: params
          expect(flash[:alert]).to eq 'You are not authorised to close this case'
          expect(response).to redirect_to root_path
        end
      end

      context 'processing' do
        before(:each) do
          sign_in @responder
          get :respond_and_close, params: params
        end

        it 'renders case close' do
          expect(response).to render_template :close
        end

        it 'returns success' do
          expect(response).to be_success
        end

        it 'assigns case' do
          expect(assigns(:case)).to eq @drafting_ovt_sar_case
        end
      end

    end

    describe '#process_respond_and_close' do
      let(:params) do
        {
          id: @drafting_ovt_sar_case.id.to_s,
          sar: {
            date_responded_dd: Date.today.day.to_s,
            date_responded_mm: Date.today.month.to_s,
            date_responded_yyyy: Date.today.year.to_s,
            missing_info: 'no'
          }
        }
      end

      context 'authorization' do
        it 'does not authorize managers' do
          sign_in manager
          patch :process_respond_and_close, params: params
          expect(flash[:alert]).to eq 'You are not authorised to close this case'
          expect(response).to redirect_to root_path
        end

        it 'authorizes responders' do
          sign_in @responder
          patch :process_respond_and_close, params: params
          expect(flash[:alert]).to be_nil
          expect(response).to redirect_to case_path(@drafting_ovt_sar_case)
        end

        it 'does not authorize approvers' do
          sign_in approver
          patch :process_respond_and_close, params: params
          expect(flash[:alert]).to eq 'You are not authorised to close this case'
          expect(response).to redirect_to root_path
        end
      end

      context 'processing' do
        before(:each)   do
          sign_in @responder

        end

        it 'redirects to cases show page' do
          patch :process_respond_and_close, params: params
          expect(response).to redirect_to case_path(@drafting_ovt_sar_case)
        end

        it 'updates case' do
          patch :process_respond_and_close, params: params
          @drafting_ovt_sar_case.reload
          expect(@drafting_ovt_sar_case.date_responded).to eq Date.today
          expect(@drafting_ovt_sar_case.current_state).to eq 'closed'
          expect(@drafting_ovt_sar_case.refusal_reason).to be_nil
        end

        it 'displays confirmation message' do
          patch :process_respond_and_close, params: params
          expect(flash[:notice]).to match(/You've closed this case/)
        end

        context 'missing info' do
          it 'updates case closure reason with tmm' do
            tmm_refusal_reason = create :refusal_reason, :sar_tmm
            params[:sar][:missing_info] = 'yes'
            patch :process_respond_and_close, params: params
            @drafting_ovt_sar_case.reload
            expect(@drafting_ovt_sar_case.date_responded).to eq Date.today
            expect(@drafting_ovt_sar_case.current_state).to eq 'closed'
            expect(@drafting_ovt_sar_case.refusal_reason).to eq tmm_refusal_reason
          end
        end

        context 'invalid parameters' do
          it 'redisplays error page' do
            params[:sar][:date_responded_dd] = Date.tomorrow.day.to_s
            patch :process_respond_and_close, params: params
            expect(response).to render_template(:closure_outcomes)
          end
        end
      end
    end
  end
end
