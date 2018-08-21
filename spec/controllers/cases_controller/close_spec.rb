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
        expect(ico_decision_attachments.first.key).to match /#{responded_ico.id}\/ico_decision\/\d{14}\/Invoice-41111225783-802805551.pdf/
      end

      it 'transitions to closed state' do
        expect(responded_ico.current_state).to eq 'closed'
      end

      it 'redirects to case path' do
        expect(response).to redirect_to case_path(responded_ico)
      end
    end


  end
end
