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
          expect(kase.refusal_reason.abbreviation).to eq 'tmm'
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
  end
end
