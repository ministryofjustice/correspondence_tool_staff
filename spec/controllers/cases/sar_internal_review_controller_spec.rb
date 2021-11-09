require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.describe Cases::SarInternalReviewController, type: :controller do
  describe 'authentication' do
    let(:params) do
      {
        correspondence_type: 'sar_internal_review',
        sar_internal_review: {
          requester_type: 'member_of_the_public',
          type: 'Standard',
          name: 'A. Member of Public',
          postal_address: '102 Petty France',
          email: 'member@public.com',
          subject: 'SAR request from controller spec',
          message: 'SAR about prisons and probation',
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
          delivery_method: :sent_by_email,
          flag_for_disclosure_specialists: false,
        }
      }
    end

    include_examples 'can_add_case policy spec', Case::SAR::InternalReview
  end

  # Not using shared_examples/new_spec due to the way  Sar IR Controller
  # sets `@case` to be a SarInternalReviewCaseForm rather than a 
  # decorator at present
  describe '#new' do
    let(:case_types) { %w[Case::SAR::InternalReview] }

    let(:klass) { Case::SAR::InternalReview }

    let(:params) { { correspondence_type: 'sar_internal_review' } }
    let(:manager) { find_or_create :disclosure_bmt_user }

    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :new, params: params }
        .to require_permission(:can_add_case?)
          .with_args(manager, klass)
    end

    it 'renders the new template' do
      get :new, params: params
      expect(response).to render_template(:new)
    end

    it 'assigns @case' do
      get :new, params: params
      expect(assigns(:case)).to be_a klass
    end

  end
end
