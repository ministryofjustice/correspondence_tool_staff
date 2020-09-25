require 'rails_helper'

RSpec.describe Cases::OffenderSarController, type: :controller do
  let(:responder) { find_or_create :branston_user }

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

    before do
      sign_in responder
    end

    context 'when the user is allowed to manage offender sar cases' do
      it 'authorizes' do
        expect { get :new, params: params }
          .to require_permission(:can_add_case?)
          .with_args(responder, Case::SAR::Offender)
      end
    end

    context 'when the user is a manager for other types' do
      let(:manager) { find_or_create :disclosure_bmt_user }

      before do
        sign_in manager
      end

      it 'redirects' do
        get :new, params: params
        expect(flash[:alert]).to eq 'You are not authorised to create new cases.'
        expect(response)
          .to redirect_to(root_path)
      end
    end

    it 'renders the new template with a form object' do
      get :new, params: params
      expect(response).to render_template(:new)
      expect(assigns(:case)).to be_a OffenderSARCaseForm
      expect(assigns(:case_types)).to eq %w[Case::SAR::Offender]
    end
  end

  describe '#create' do
    before do
      sign_in responder
      post :create, params: params
      expect(assigns(:case)).to be_a Case::SAR::Offender
      expect(flash[:notice]).to eq nil
    end

    context 'partial validations' do
      let(:errors) { assigns(:case).errors.messages }

      context 'for step subject-details' do
        let(:params) do
          {
            current_step: 'subject-details',
            offender_sar: {
              subject_full_name: '',
              subject_address: '',
            }
          }
        end

        it 'validates subject name and address' do
          expect(errors[:subject_full_name]).to eq ["can't be blank"]
          expect(errors[:subject_address]).to eq ["can't be blank"]
        end

        # unset radio options and date fields are hard to validate
        # so offender_sar_case_form#params_for_step
        # contains logic to set required ones if missing
        it 'sets empty values and validates other fields' do
          errors = assigns(:case).errors.messages
          expect(errors[:date_of_birth]).to eq ["can't be blank"]
          expect(errors[:subject_type]).to eq ["can't be blank"]
          expect(errors[:flag_as_high_profile]).to eq ["can't be blank"]
        end
      end

      context 'for step requester-details' do
        context 'when third party absent' do
          let(:params) do
            {
              current_step: 'requester-details',
              offender_sar: {
                third_party_relationship: '',
                third_party_name: '',
                third_party_company_name: '',
                postal_address: '',
              }
            }
          end

          it 'requires third_party to be set' do
            expect(errors[:third_party]).to eq ["can't be blank"]
          end
        end

        context 'when third party true' do
          let(:params) do
            {
              current_step: 'requester-details',
              offender_sar: {
                third_party: true,
                third_party_relationship: '',
                third_party_name: '',
                third_party_company_name: '',
                postal_address: '',
              }
            }
          end

          it 'validates requester details' do
            expect(errors[:third_party_name]).to eq ["can't be blank if company name not given"]
            expect(errors[:third_party_company_name]).to eq ["can't be blank if representative name not given"]
            expect(errors[:third_party_relationship]).to eq ["can't be blank"]
            expect(errors[:postal_address]).to eq ["can't be blank"]
          end
        end

        context 'when third party false' do
          let(:params) do
            {
              current_step: 'requester-details',
              offender_sar: {
                third_party: false,
                third_party_relationship: '',
                third_party_name: '',
                third_party_company_name: '',
                postal_address: '',
              }
            }
          end

          it 'unsets fields that should be ignored' do
            expect(errors[:third_party_name]).to be_empty
            expect(errors[:third_party_company_name]).to be_empty
            expect(errors[:third_party_relationship]).to be_empty
            expect(errors[:postal_address]).to be_empty
          end
        end
      end

      context 'for step recipient-details' do
        context 'when third party absent' do
          let(:params) do
            {
              current_step: 'recipient-details',
              offender_sar: {
                third_party_relationship: '',
                third_party_name: '',
                third_party_company_name: '',
                postal_address: '',
              }
            }
          end

          it 'requires recipient to be set' do
            expect(errors[:recipient]).to eq ["can't be blank"]
          end
        end

        context 'when recipient is third party' do
          let(:params) do
            {
              current_step: 'recipient-details',
              offender_sar: {
                recipient: 'third_party_recipient',
                third_party_relationship: '',
                third_party_name: '',
                third_party_company_name: '',
                postal_address: '',
              }
            }
          end

          it 'validates recipient details' do
            expect(errors[:third_party_name]).to eq ["can't be blank if company name not given"]
            expect(errors[:third_party_company_name]).to eq ["can't be blank if representative name not given"]
            expect(errors[:third_party_relationship]).to eq ["can't be blank"]
            expect(errors[:postal_address]).to eq ["can't be blank"]
          end
        end
      end
    end

    context 'for step requested-info' do
    end

    context 'for step request-details'
    context 'for step date-received'
  end

  describe 'transitions' do
    OFFENDER_SAR_STATES = {
      data_to_be_requested: :mark_as_waiting_for_data,
      waiting_for_data: :mark_as_ready_for_vetting,
      ready_for_vetting: :mark_as_vetting_in_progress,
      vetting_in_progress: :mark_as_ready_to_copy,
      ready_to_copy: :mark_as_ready_to_dispatch,
      ready_to_dispatch: :close,
    }.freeze

    OFFENDER_SAR_STATES.each do |state, transition_event|
      context "with Offender SAR in #{state} state" do
        it_behaves_like 'edit offender sar spec', state.to_sym, transition_event
      end
    end
  end

  describe '#edit' do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) {{ id: offender_sar_case.id }}

    before do
      sign_in responder
    end

    it 'assigns and displays' do
      get :edit, params: params
      expect(response).to render_template(:edit)
      expect(assigns(:case)).to be_a Case::SAR::Offender
    end
  end

  describe '#update' do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) {{ id: offender_sar_case.id }}
    let(:params) do
      {
        id: offender_sar_case.id,
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

    let(:same_params) {{ id: offender_sar_case.id }}
    let(:same_params) do
      {
        id: offender_sar_case.id,
        offender_sar: {
          name: offender_sar_case.name,
          postal_address: offender_sar_case.postal_address,
          subject: offender_sar_case.subject,
          message: offender_sar_case.message,
        }
      }
    end

    before do
      sign_in responder
    end

    context 'without change anything' do
      it 'check the flash' do
        patch :update, params: same_params
        expect(assigns(:case)).to be_a Case::SAR::Offender
        expect(flash[:notice]).to eq nil
        expect(flash[:alert]).to eq 'No changes were made'
        expect(offender_sar_case.object.transitions.where(event: "edit_case").count).to eq 0
      end
    end

    context 'with valid params' do
      before(:each) do
        patch :update, params: params
        expect(assigns(:case)).to be_a Case::SAR::Offender
      end

      it 'sets the flash' do
        expect(offender_sar_case.object.transitions.where(event: "edit_case").count).to be >= 1
        expect(flash[:notice]).to eq 'Case updated'
      end

      it 'redirects to the new case assignment page' do
        expect(response)
          .to redirect_to(case_path(offender_sar_case))
      end
    end

  end
end
