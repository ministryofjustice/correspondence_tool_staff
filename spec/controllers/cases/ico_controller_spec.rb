require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.describe Cases::IcoController, type: :controller do
  describe 'FOI' do
    describe '#close' do
      let(:kase) { create :responded_ico_foi_case }

      include_examples 'close spec', described_class
    end

    describe '#closure_outcomes' do
      let(:kase) { create :responded_ico_foi_case }

      include_examples 'closure outcomes spec', described_class
    end

    describe '#edit_closure' do
      let(:kase)    { create :closed_ico_foi_case }
      let(:manager) { find_or_create :disclosure_bmt_user }

      include_examples 'edit closure spec', described_class
    end

    describe '#confirm_respond' do
      let(:approver) { find_or_create :disclosure_specialist }
      let(:approved_ico) { create :approved_ico_foi_case }
      let(:date_responded) { approved_ico.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: 'ico',
          ico:  {
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

    describe '#update_closure' do
      before(:all) do
        CaseClosure::MetadataSeeder.seed!
      end

      after(:all) do
        DbHousekeeping.clean
      end

      let(:manager)   { find_or_create :disclosure_bmt_user }
      let(:responder) { create :foi_responder }
      let(:kase) { create :closed_ico_foi_case, :overturned_by_ico }
      let(:new_date_responded) { 1.business_day.before(kase.date_ico_decision_received) }

      context 'closed ICO' do
        context 'change to upheld' do
          let(:params)             { {
            id: kase.id,
            ico: {
              date_ico_decision_received_yyyy: kase.created_at.year,
              date_ico_decision_received_mm: kase.created_at.month,
              date_ico_decision_received_dd: kase.created_at.day,
              ico_decision: 'upheld',
              ico_decision_comment: 'ayt',
              uploaded_ico_decision_files: ['uploads/71/request/request.pdf']
            }
          } }
          before do
            sign_in manager
            patch :update_closure, params: params
          end

          it 'updates the cases date responded field' do
            kase.reload
            expect(kase.date_ico_decision_received).to eq kase.created_at.to_date
          end

          it 'updates the cases refusal reason' do
            kase.reload
            expect(kase.ico_decision).to eq 'upheld'
          end

          it 'redirects to the case details page' do
            expect(response).to redirect_to case_path(id: kase.id)
          end
        end

        context 'no ico decison files specified' do
          let(:params)             { {
            id: kase.id,
            ico: {
              date_ico_decision_received_yyyy: kase.created_at.year,
              date_ico_decision_received_mm: kase.created_at.month,
              date_ico_decision_received_dd: kase.created_at
                .day,
              ico_decision: 'upheld',
              ico_decision_comment: 'ayt',
            }
          } }
          before do
            sign_in manager
            patch :update_closure, params: params
          end

          it 'updates the cases date responded field' do
            kase.reload
            expect(kase.date_ico_decision_received).to eq kase.created_at.to_date
          end

          it 'updates the cases refusal reason' do
            kase.reload
            expect(kase.ico_decision).to eq 'upheld'
          end

          it 'redirects to the case details page' do
            expect(response).to redirect_to case_path(id: kase.id)
          end
        end

        context 'change to overturned' do
          let(:kase)         { create :closed_ico_foi_case, date_ico_decision_received: Date.today }
          let(:params)       { {
            id: kase.id,
            ico: {
              date_ico_decision_received_yyyy: new_date_responded.year,
              date_ico_decision_received_mm: new_date_responded.month,
              date_ico_decision_received_dd: new_date_responded.day,
              ico_decision: 'overturned',
              ico_decision_comment: 'ayt',
              uploaded_ico_decision_files: ['uploads/71/request/request.pdf']
            }
          } }
          before do
            sign_in manager
            patch :update_closure, params: params
          end

          it 'updates the cases date responded field' do
            kase.reload
            expect(kase.date_ico_decision_received).to eq new_date_responded
          end

          it 'updates the cases refusal reason' do
            kase.reload
            expect(kase.ico_decision).to eq 'overturned'
          end

          it 'redirects to the case details page' do
            expect(response).to redirect_to case_path(id: kase.id)
          end
        end
      end

      context 'open ICO' do
        let(:kase) { create :accepted_ico_foi_case }
        let(:new_date_responded) { 1.business_day.ago }

        let(:params)             { {
          id: kase.id,
          ico: {
            date_ico_decision_received_yyyy: new_date_responded.year,
            date_ico_decision_received_mm: new_date_responded.month,
            date_ico_decision_received_dd: new_date_responded.day,
            ico_decision: 'overturned',
          }
        } }


        before do
          sign_in manager
          patch :update_closure, params: params
        end


        it 'updates the cases date responded field' do
          kase.reload
          expect(kase.date_ico_decision_received).not_to eq new_date_responded
        end

        it 'updates the cases refusal reason' do
          kase.reload
          expect(kase.ico_decision).not_to eq 'upheld'
        end

        it 'redirects to the case details page' do
          expect(response).to redirect_to case_path(id: kase.id)
        end
      end
    end
  end

  describe 'SAR' do
    describe '#closure_outcomes' do
      let(:kase) { create :responded_ico_sar_case }

      include_examples 'closure outcomes spec', described_class
    end

    describe '#edit_closure' do
      let(:kase)    { create :closed_ico_sar_case }
      let(:manager) { find_or_create :disclosure_bmt_user }

      include_examples 'edit closure spec', described_class
    end
  end
end
