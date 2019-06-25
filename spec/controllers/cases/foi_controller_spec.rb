require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.describe Cases::FoiController, type: :controller do
  describe 'closeable' do
    describe '#closure_outcomes' do
      let(:kase) { create :responded_case }

      include_examples 'closure outcomes spec', described_class
    end

    describe '#respond' do
      let(:responder) { find_or_create(:foi_responder) }
      let(:responding_team) { responder.responding_teams.first }
      let(:kase) {
        create(
          :case_with_response,
          responder: responder,
          responding_team: responding_team
        )
      }

      include_examples 'respond spec', described_class
    end

    describe '#confirm_respond' do
      let(:kase) { create :case_with_response }

      include_examples 'confirm respond spec', described_class
    end

    describe '#process_closure' do
      context 'with valid params' do
        let(:responder) { find_or_create :foi_responder }
        let(:responding_team) { responder.responding_teams.first }
        let(:outcome) { find_or_create :outcome, :requires_refusal_reason }
        let(:info_held) { find_or_create :info_status, :held }
        let(:date_responded) { 3.days.ago }
        let(:kase) {
          create(
            :responded_case,
            responder: responder,
            responding_team: responding_team,
            received_date: 5.days.ago
          )
        }
        let(:params) {
          {
            id: kase.id,
            foi: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              info_held_status_abbreviation: info_held.abbreviation,
              outcome_abbreviation: outcome.abbreviation,
            }
          }
        }

        include_examples 'process closure spec', described_class
      end

      context 'FOI internal review' do
        let(:appeal_outcome) { find_or_create :appeal_outcome, :upheld }
        let(:internal_review) { create :responded_compliance_review }
        let(:manager) { find_or_create :disclosure_bmt_user }
        let(:info_held) { find_or_create :info_status, :not_held }
        let(:date_responded) { 3.days.ago }
        let(:params) {
          {
            id: internal_review.id,
            foi: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
              info_held_status_abbreviation: info_held.abbreviation,
              appeal_outcome_name: appeal_outcome.name,
            }
          }
        }

        before { sign_in manager }

        it "closes a case that has been responded to" do
          patch :process_closure, params: params
          internal_review.reload

          expect(internal_review.current_state).to eq 'closed'
          expect(internal_review.appeal_outcome_id).to eq appeal_outcome.id
          expect(internal_review.date_responded).to eq 3.days.ago.to_date
        end
      end
    end

    describe '#process_date_responded' do
      let(:kase) { create :responded_case, creation_time: 6.business_days.ago }

      include_examples 'process date responded spec', described_class
    end

    describe '#update_closure' do
      before(:all) do
        CaseClosure::MetadataSeeder.seed!
      end

      after(:all) do
        DbHousekeeping.clean
      end

      let(:responder) { create :foi_responder }
      let(:manager)   { find_or_create :disclosure_bmt_user }
      let(:new_date_responded) { 1.business_day.before(kase.date_responded) }
      let(:closure_params) {
        {
          info_held_status_abbreviation: 'not_held'
        }
      }
      let(:params) {
        {
          id: kase.id,
          foi: {
            date_responded_yyyy: new_date_responded.year,
            date_responded_mm: new_date_responded.month,
            date_responded_dd: new_date_responded.day,
          }.merge(closure_params)
        }
      }

      before do
        sign_in manager
      end

      context 'when closed' do
        let(:kase) { create :closed_case }

        it 'redirects to the case details page' do
          patch :update_closure, params: params
          expect(response).to redirect_to case_path(id: kase.id)
        end

        it 'updates the cases date responded field' do
          patch :update_closure, params: params
          kase.reload
          expect(kase.date_responded).to eq new_date_responded
        end

        context 'being updated to be held in full and granted' do
          let(:kase) { create :closed_case, :info_not_held }
          let(:closure_params) {
            {
              info_held_status_abbreviation: 'held',
              outcome_abbreviation: 'granted',
              refusal_reason_abbreviation: nil,
              exemption_ids: [],
            }
          }

          it 'redirects to the case details page' do
            patch :update_closure, params: params
            expect(response).to redirect_to case_path(id: kase.id)
          end

          it 'updates the cases refusal reason' do
            patch :update_closure, params: params
            kase.reload
            expect(kase.info_held_status).to be_held
            expect(kase.outcome).to be_granted
          end
        end

        context 'being updated to be not held' do
          let(:kase) { create :closed_case }
          let(:closure_params) {
            {
              info_held_status_abbreviation: 'not_held',
              outcome_abbreviation: nil,
              refusal_reason_abbreviation: nil,
              exemption_ids: [],
            }
          }

          it 'redirects to the case details page' do
            patch :update_closure, params: params
            expect(response).to redirect_to case_path(id: kase.id)
          end

          it 'updates the cases refusal reason' do
            patch :update_closure, params: params
            kase.reload
            expect(kase.info_held_status).to be_not_held
          end
        end

        context 'being updated to be held in part and refused' do
          let(:kase) { create :closed_case, :other_vexatious }
          let(:closure_params) {
            {
              info_held_status_abbreviation: 'part_held',
              outcome_abbreviation: 'refused',
              refusal_reason_abbreviation: nil,
              exemption_ids: [ CaseClosure::Exemption.s12.id.to_s ]
            }
          }

          it 'redirects to the case details page' do
            patch :update_closure, params: params
            expect(response).to redirect_to case_path(id: kase.id)
          end

          it 'updates the cases refusal reason' do
            patch :update_closure, params: params
            kase.reload
            expect(kase.info_held_status).to be_part_held
          end
        end

        context 'being updated to be other' do
          let(:kase) { create :closed_case, :other_vexatious }
          let(:closure_params) {
            {
              info_held_status_abbreviation: 'not_confirmed',
              outcome_abbreviation: nil,
              refusal_reason_abbreviation: 'cost',
              exemption_ids: [],
            }
          }

          it 'redirects to the case details page' do
            patch :update_closure, params: params
            expect(response).to redirect_to case_path(id: kase.id)
          end

          it 'updates the cases refusal reason' do
            patch :update_closure, params: params
            kase.reload
            expect(kase.info_held_status).to be_not_confirmed
          end
        end
      end

      context 'when open' do
        let(:new_date_responded) { 1.business_day.ago }
        let(:kase)               { create :foi_case }

        it 'does not change the date responded' do
          patch :update_closure, params: params
          kase.reload
          expect(kase.date_responded).not_to eq new_date_responded
        end

        it 'does not update the cases refusal reason' do
          patch :update_closure, params: params
          kase.reload
          expect(kase.refusal_reason).to be_nil
        end

        it 'redirects to the case details page' do
          patch :update_closure, params: params
          expect(response).to redirect_to case_path(id: kase.id)
        end
      end
    end
  end
end

