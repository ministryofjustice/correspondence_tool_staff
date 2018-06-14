require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

describe CasesController do
  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    DbHousekeeping.clean
  end

  let(:manager) { create :disclosure_bmt_user }

  describe 'PATCH update_closure' do
    context 'SAR cases' do
      let(:new_date_responded) { 1.business_day.before(kase.date_responded) }
      let(:params)             { {
                                   id: kase.id,
                                   case_sar: {
                                     date_responded_yyyy: new_date_responded.year,
                                     date_responded_mm: new_date_responded.month,
                                     date_responded_dd: new_date_responded.day,
                                     missing_info: 'yes',
                                   }
                                 } }

      before do
        sign_in manager
        patch :update_closure, params: params
      end

      context 'closed SAR case' do
        let(:kase) { create :closed_sar }

        before do
          sign_in manager
          patch :update_closure, params: params
        end

        it 'updates the cases date responded field' do
          kase.reload
          expect(kase.date_responded).to eq new_date_responded
        end

        it 'updates the cases refusal reason' do
          kase.reload
          expect(kase.refusal_reason).to eq CaseClosure::RefusalReason.tmm
        end

        it 'redirects to the case details page' do
          expect(response).to redirect_to case_path(id: kase.id)
        end
      end

      context 'an open SAR case' do
        let(:new_date_responded) { 1.business_day.ago }
        let(:kase)               { create :sar_case }

        it 'does not change the date responded' do
          kase.reload
          expect(kase.date_responded).not_to eq new_date_responded
        end

        it 'does not update the cases refusal reason' do
          kase.reload
          expect(kase.refusal_reason).to be_nil
        end

        it 'redirects to the case details page' do
          expect(response).to redirect_to case_path(id: kase.id)
        end
      end
    end

    context 'FOI case' do
      let(:new_date_responded) { 1.business_day.before(kase.date_responded) }
      let(:closure_params) {
        {
          info_held_status_abbreviation: 'not_held'
        }
      }
      let(:params) {
        params = {
          id: kase.id,
          case_foi: {
            date_responded_yyyy: new_date_responded.year,
            date_responded_mm: new_date_responded.month,
            date_responded_dd: new_date_responded.day,
          }.merge(closure_params)
        }
        params
      }

      before do
        sign_in manager
      end

      context 'that is closed' do
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
              exemption_ids: {},
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
              exemption_ids: {},
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
            exemption_s12 = find_or_create(:exemption, :s12_1)
            {
              info_held_status_abbreviation: 'part_held',
              outcome_abbreviation: 'refused',
              refusal_reason_abbreviation: nil,
              exemption_ids: { CaseClosure::Exemption.s12.id.to_s => '1' }
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
              exemption_ids: {},
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

      context 'that is open' do
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
