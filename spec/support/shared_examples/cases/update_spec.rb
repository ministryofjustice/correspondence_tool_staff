require 'rails_helper'

RSpec.shared_examples 'update case spec' do
  before do
    sign_in manager
  end

  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:now)     { Time.local(2018, 5, 30, 10, 23, 33) }
  let(:received_date) {
    Date.new(
      params[correspondence_type_abbr]['received_date_yyyy'].to_i,
      params[correspondence_type_abbr]['received_date_mm'].to_i,
      params[correspondence_type_abbr]['received_date_dd'].to_i
    )
  }
  let(:date_draft_compliant) {
    Date.new(
      params[correspondence_type_abbr]['date_draft_compliant_yyyy'].to_i,
      params[correspondence_type_abbr]['date_draft_compliant_mm'].to_i,
      params[correspondence_type_abbr]['date_draft_compliant_dd'].to_i
    )
  }

  context 'with valid params' do
    it 'updates the case' do
      Timecop.freeze(now) do
        patch :update, params: params
        kase.reload

        expect(kase.name).to eq params[correspondence_type_abbr]['name']
        expect(kase.email).to eq params[correspondence_type_abbr]['email']
        expect(kase.message).to eq params[correspondence_type_abbr]['message']
        expect(kase.received_date).to eq received_date
        expect(kase.postal_address).to eq params[correspondence_type_abbr]['postal_address']
        expect(kase.subject).to eq params[correspondence_type_abbr]['subject']
        expect(kase.date_draft_compliant).to eq date_draft_compliant

        # Bespoke params check
        valid_params_check
      end
    end

    it 'redirects to show page' do
      Timecop.freeze(now) do
        patch :update, params: params
        expect(response).to redirect_to case_path(kase.id)
      end
    end
  end

  context 'with invalid params' do
    context 'received_date too far int past' do
      before(:each) { params[correspondence_type_abbr]['received_date_yyyy'] = '2017' }

      it 'does not update the record' do
        Timecop.freeze(now) do
          original_kase = kase.clone
          patch :update, params: params
          expect(kase.reload).to eq original_kase
        end
      end

      it 'has error details on the record' do
        patch :update, params: params
        expect(assigns(:case).errors.full_messages).to eq ['Received date too far in past.']
      end

      it 'redisplays the edit page' do
        patch :update, params: params
        expect(response).to render_template :edit
      end
    end

    context 'date draft compliant before received date' do
      it 'has error details on the record' do
        Timecop.freeze(now) do
          kase.date_responded = 3.business_days.after(kase.received_date)
          params[correspondence_type_abbr]['date_draft_compliant_yyyy'] = '2016'
          patch :update, params: params
          expect(assigns(:case).errors.full_messages).to eq ["Date compliant draft uploaded can't be before date received"]
        end
      end
    end

    context 'date draft compliant in future' do
      it 'has error details on the record' do
        Timecop.freeze(now) do
          params[correspondence_type_abbr]['date_draft_compliant_yyyy'] = '2020'
          patch :update, params: params
          expect(assigns(:case).errors.full_messages).to eq ['Date compliant draft uploaded can\'t be in the future.']
        end
      end
    end

    context 'date draft compliant before received date' do
      it 'has error details on the record' do
        Timecop.freeze(now) do
          params[correspondence_type_abbr]['date_draft_compliant_yyyy'] = '2016'
          patch :update, params: params
          expect(assigns(:case).errors.full_messages).to eq ["Date compliant draft uploaded can't be before date received"]
        end
      end
    end
  end
end
