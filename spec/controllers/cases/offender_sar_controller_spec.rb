require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.describe Cases::OffenderSarController, type: :controller do
  describe 'authentication' do
    let(:params) do
      {
        correspondence_type: 'offender_sar',
        offender_sar: {
          requester_type: 'member_of_the_public',
          type: 'Offender',
          name: 'A. N. Other',
          postal_address: '102 Petty France',
          email: 'member@public.com',
          subject: 'Offender SAR request from controller spec',
          message: 'Offender SAR about a former offender',
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
          delivery_method: :sent_by_email,
          flag_for_disclosure_specialists: false,
        }
      }
    end

    include_examples 'can_add_case policy spec', Case::SAR::Offender
  end

  # Not using shared_examples/new_spec due to the way Offender Sar Controller
  # sets `@case` to be a OffenderSARCaseForm rather than a decorator at present
  describe '#new' do
    let(:case_types) { %w[Case::SAR::Offender] }
    let(:params) {{ correspondence_type: 'offender_sar' }}
    let(:manager) { find_or_create :disclosure_bmt_user }

    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :new, params: params }
        .to require_permission(:can_add_case?)
          .with_args(manager, Case::SAR::Offender)
    end

    it 'renders the new template with a form object' do
      get :new, params: params
      expect(response).to render_template(:new)
      expect(assigns(:case)).to be_a OffenderSARCaseForm
      expect(assigns(:case_types)).to eq %w[Case::SAR::Offender]
    end
  end
end
