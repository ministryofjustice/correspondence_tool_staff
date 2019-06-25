require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.describe Cases::SarController, type: :controller do
  describe 'closeable' do
    describe '#edit_closure' do
      context 'SAR case' do
        let(:kase)    { create :closed_sar }
        let(:manager) { find_or_create :disclosure_bmt_user }

        before do
          sign_in manager
        end

        it 'authorises with update_closure? policy' do
          expect{
            get :edit_closure, params: { id: kase.id }
          }.to require_permission(:update_closure?)
            .with_args(manager, kase)
        end

        it 'renders the close page' do
          get :edit_closure, params: { id: kase.id }
          expect(response).to render_template :edit_closure
        end
      end
    end

    describe '#process_closure' do
      let(:sar) { create :accepted_sar }
      let(:responder) { sar.responder }
      let(:another_responder) { create :responder }

      before(:all) do
        CaseClosure::MetadataSeeder.seed!
      end

      after(:all) do
        CaseClosure::MetadataSeeder.unseed!
      end

      before do
        allow(ActionNotificationsMailer).to receive_message_chain(:notify_team,
          :deliver_later)
      end

      it "closes a case that has been responded to" do
        sign_in responder
        patch :process_respond_and_close, params: sar_closure_params(sar)
        expect(Case::SAR::Standard.first.current_state).to eq 'closed'
        expect(Case::SAR::Standard.first.refusal_reason_id).to eq CaseClosure::RefusalReason.sar_tmm.id
        expect(Case::SAR::Standard.first.date_responded).to eq 3.days.ago.to_date
        expect(ActionNotificationsMailer)
          .to have_received(:notify_team)
            .with(sar.managing_team, sar, 'Case closed')
      end

      context 'not the assigned responder' do
        it "does not progress the case" do
          sign_in another_responder
          patch :process_respond_and_close, params: sar_closure_params(sar)
          expect(Case::SAR::Standard.first.current_state).to eq 'drafting'
          expect(Case::SAR::Standard.first.date_responded).to be nil
          expect(ActionNotificationsMailer)
            .not_to have_received(:notify_team)
              .with(sar.managing_team, sar, 'Case closed')
        end
      end

      def sar_closure_params(sar)
        date_responded = 3.days.ago
        {
          id: sar.id,
          sar: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
            missing_info: 'yes'
          }
        }
      end
    end
  end
end
