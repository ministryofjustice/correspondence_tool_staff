require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

RSpec.describe Cases::FoiController, type: :controller do
  describe '#new' do
    let(:case_types) {
      %w[
        Case::FOI::Standard
        Case::FOI::TimelinessReview
        Case::FOI::ComplianceReview
      ]
    }

    let(:params) { { correspondence_type: 'foi' } }

    include_examples 'new case spec', Case::FOI::Standard
  end

  describe '#create' do
    let(:manager) { create :manager }
    let(:foi_params) do
      {
        correspondence_type: 'foi',
        foi: {
          requester_type: 'member_of_the_public',
          type: 'Standard',
          name: 'A. Member of Public',
          postal_address: '102 Petty France',
          email: 'member@public.com',
          subject: 'FOI request from controller spec',
          message: 'FOI about prisons and probation',
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
          delivery_method: :sent_by_email,
          flag_for_disclosure_specialists: false,
          uploaded_request_files: ['uploads/71/request/request.pdf'],
        }
      }
    end

    context "as an authenticated manager" do
      before do
        sign_in manager
        find_or_create :team_dacu
        find_or_create :team_dacu_disclosure
      end

      let(:created_case) { Case::FOI::Standard.first }

      it 'makes a DB entry' do
        expect { post :create, params: foi_params }.
          to change { Case::FOI::Standard.count }.by 1
      end

      it 'uses the params provided' do
        post :create, params: foi_params

        expect(created_case.requester_type).to eq 'member_of_the_public'
        expect(created_case.type).to eq 'Case::FOI::Standard'
        expect(created_case.name).to eq 'A. Member of Public'
        expect(created_case.postal_address).to eq '102 Petty France'
        expect(created_case.email).to eq 'member@public.com'
        expect(created_case.subject).to eq 'FOI request from controller spec'
        expect(created_case.message).to eq 'FOI about prisons and probation'
        expect(created_case.received_date).to eq Time.zone.today

        expect(flash[:notice]).to eq "FOI case created<br/>Case number: #{created_case.number}"
      end

      it "create a internal review for timeliness" do
        foi_params[:foi][:type] = 'TimelinessReview'
        post :create, params: foi_params
        expect(created_case.type).to eq 'Case::FOI::TimelinessReview'
      end

      it "create a internal review for compliance" do
        foi_params[:foi][:type] = 'ComplianceReview'
        post :create, params: foi_params
        expect(created_case.type).to eq 'Case::FOI::ComplianceReview'
      end

      context 'flag_for_clearance' do
        let!(:service) do
          double(CaseFlagForClearanceService, call: true).tap do |svc|
            allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
          end
        end

        it 'does not flag for clearance if parameter is not set' do
          foi_params[:foi].delete(:flag_for_disclosure_specialists)
          expect { post :create, params: foi_params }
            .not_to change { Case::FOI::Standard.count }
          expect(service).not_to have_received(:call)
        end

        it "returns an error message if parameter is not set" do
          foi_params[:foi].delete(:flag_for_disclosure_specialists)
          post :create, params: foi_params
          expect(assigns(:case).errors).to have_key(:flag_for_disclosure_specialists)
          expect(response).to have_rendered(:new)
        end

        it "flags the case for clearance if parameter is true" do
          foi_params[:foi][:flag_for_disclosure_specialists] = 'yes'
          post :create, params: foi_params
          expect(service).to have_received(:call)
        end

        it "does not flag the case for clearance if parameter is false" do
          foi_params[:foi][:flag_for_disclosure_specialists] = false
          post :create, params: foi_params
          expect(service).not_to have_received(:call)
        end
      end

      context 'with invalid params' do
        let(:invalid_foi_params) {
          foi_params.tap do |p|
            p[:foi][:type] = 'standard'
            p[:foi][:name] = ''
            p[:foi][:email] = nil
          end
        }

        it 're-renders new page' do
          post :create, params: invalid_foi_params

          expect(response).to have_rendered(:new)
          expect(assigns(:case_types)).to eq [
            'Case::FOI::Standard',
            'Case::FOI::TimelinessReview',
            'Case::FOI::ComplianceReview',
          ]
          expect(assigns(:case)).to be_an_instance_of(Case::FOI::Standard)
          expect(assigns(:s3_direct_post)).to be_present
        end
      end

      context 'with invalid FOI type' do
        let(:invalid_foi_params) {
          foi_params.tap do |p|
            p[:foi][:type] = 'totally_madeup'
          end
        }

        it 'raises an exception' do
          assert_raises { post :create, params: invalid_foi_params }
        end
      end
    end
  end

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

