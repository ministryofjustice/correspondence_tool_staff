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
          received_date_dd: Time.current.to_date.day.to_s,
          received_date_mm: Time.current.to_date.month.to_s,
          received_date_yyyy: Time.current.to_date.year.to_s,
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

  describe '#create' do
    let(:third_party_true_params) do
      { 
        "sar_internal_review":  {
          "subject_type"=>"offender",
          "sar_ir_subtype"=>"timeliness",
          "name"=>"Fred Jones",
          "third_party_relationship"=>"Solicitor",
          "third_party"=>"false",
          "received_date_dd"=>"27",
          "received_date_mm"=>"01",
          "received_date_yyyy"=>"2022",
          "subject"=>"IR of 220127001 - Some info",
          "message"=>"asd",
          "flag_for_disclosure_specialists"=>"yes",
          "reply_method"=>"send_by_email",
          "email"=>"asd@asd.com",
          "postal_address"=>"",
          "current_step"=>"case-details"
        }
      }
    end

    let(:third_party_false_params) do
      { 
        "sar_internal_review":  {
          "subject_type"=>"offender",
          "sar_ir_subtype"=>"timeliness",
          "name"=>"Fred Jones",
          "third_party_relationship"=>"Solicitor",
          "third_party"=>"true",
          "received_date_dd"=>"27",
          "received_date_mm"=>"01",
          "received_date_yyyy"=>"2022",
          "subject"=>"IR of 220127001 - Some info",
          "message"=>"asd",
          "flag_for_disclosure_specialists"=>"yes",
          "reply_method"=>"send_by_email",
          "email"=>"asd@asd.com",
          "postal_address"=>"",
          "current_step"=>"case-details"
        }
      }
    end

    it 'if third party is false then details are nil in processed params' do
      post :create, params: third_party_true_params

      processed_params = subject.create_params
      expect(processed_params[:name]).to be(nil)
      expect(processed_params[:third_party]).to match("false")
      expect(processed_params[:third_party_relationship]).to be(nil)
    end

    it 'if third party is true then details are not nil in processed params' do
      post :create, params: third_party_false_params

      processed_params = subject.create_params
      expect(processed_params[:name]).to match("Fred Jones")
      expect(processed_params[:third_party]).to match("true")
      expect(processed_params[:third_party_relationship]).to match("Solicitor")
    end
  end
end

