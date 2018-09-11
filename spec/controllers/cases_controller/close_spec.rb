require 'rails_helper'

describe CasesController do

  let(:responded_ico)       { create :responded_ico_foi_case }
  let(:today)               { Date.today }
  let(:manager)             { create :manager }
  let(:responder)           { create :responder }
  let(:approver)            { create :approver }
  let(:params) do
    {
        id: responded_ico.id.to_s,
        case_ico: {
            date_ico_decision_received_dd: today.day.to_s,
            date_ico_decision_received_mm: today.month.to_s,
            date_ico_decision_received_yyyy: today.year.to_s,
            ico_decision: 'upheld',
            uploaded_ico_decision_files: [ 'uploads/2/responses/Invoice-41111225783-802805551.pdf' ],
            ico_decision_comment: 'This is a closure comment'
        }
    }
  end

  describe '#process_closure' do
    describe 'authorization' do
      it 'authorizes managers' do
        sign_in manager
        allow_any_instance_of(S3Uploader).to receive(:remove_leftover_upload_files)
        expect {
          post :process_closure, params: params
        }.to require_permission(:can_close_case?).with_args(manager, responded_ico)
        expect(response).to redirect_to case_path(responded_ico)
      end

      it 'does not authorize responders' do
        sign_in responder
        post :process_closure, params: params
        expect(flash[:alert]).to eq 'You are not authorised to close this case'
        expect(response).to redirect_to root_path
      end

      it 'does not authorize approvers' do
        sign_in approver
        post :process_closure, params: params
        expect(flash[:alert]).to eq 'You are not authorised to close this case'
        expect(response).to redirect_to root_path
      end
    end

    describe 'successful closure' do
      before(:each) do
        sign_in manager
        allow_any_instance_of(S3Uploader).to receive(:remove_leftover_upload_files)
        post :process_closure, params: params
        responded_ico.reload
      end

      it 'updates the date_ico_decision_received' do
        expect(responded_ico.date_ico_decision_received).to eq today
      end

      it 'udpates the outcome' do
        expect(responded_ico.ico_decision).to eq 'upheld'
      end

      it 'adds attachments' do
        ico_decision_attachments = responded_ico.attachments.ico_decisions
        expect(ico_decision_attachments.size).to eq 1
        expect(ico_decision_attachments.first.key).to match(/#{responded_ico.id}\/ico_decision\/\d{14}\/Invoice-41111225783-802805551.pdf/)
      end

      it 'transitions to closed state' do
        expect(responded_ico.current_state).to eq 'closed'
      end

      it 'redirects to case path' do
        expect(response).to redirect_to case_path(responded_ico)
      end
    end


  end



  context 'overturned SAR' do

    before(:all)   do
      @responder = create :responder
      @drafting_ovt_sar_case = create :accepted_ot_ico_sar, responder: @responder
    end

    after(:all)    { DbHousekeeping.clean }

    describe 'respond_and_close' do

      let(:params)    { {id: @drafting_ovt_sar_case.id.to_s} }

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

    describe 'process_respond_and_close' do

      let(:params) do
        {
            id: @drafting_ovt_sar_case.id.to_s,
            case_sar: {
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
            tmm_refusal_reason = create :refusal_reason, :tmm
            params[:case_sar][:missing_info] = 'yes'
            patch :process_respond_and_close, params: params
            @drafting_ovt_sar_case.reload
            expect(@drafting_ovt_sar_case.date_responded).to eq Date.today
            expect(@drafting_ovt_sar_case.current_state).to eq 'closed'
            expect(@drafting_ovt_sar_case.refusal_reason).to eq tmm_refusal_reason
          end
        end

        context 'invalid parameters' do
          it 'redisplays error page' do
            params[:case_sar][:date_responded_dd] = Date.tomorrow.day.to_s
            patch :process_respond_and_close, params: params
            expect(response).to render_template(:close)
          end
        end
      end
    end
  end
end
