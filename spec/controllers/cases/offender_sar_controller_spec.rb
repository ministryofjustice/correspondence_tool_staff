require 'rails_helper'

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

  fdescribe '#edit' do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) {{ id: offender_sar_case.id }}
    it 'does stuff' do
      get :edit, params: params
      expect(response).to render_template(:edit)
      expect(assigns(:case)).to be_a Case::SAR::Offender
    end
  end

  fdescribe '#update' do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) {{ id: offender_sar_case.id }}
    it 'does stuff' do
      patch :update, params: params
      expect(response).to render_template(:show)
      expect(assigns(:case)).to be_a Case::SAR::Offender
    end
  end
end
