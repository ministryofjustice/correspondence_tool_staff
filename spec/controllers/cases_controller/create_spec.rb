require 'rails_helper'

describe CasesController do
  let(:manager)               { create :manager }
  let(:responder)             { create :responder }

  describe 'POST create' do
    context 'FOI case' do
      context 'as an authenticated responder' do
        before { sign_in responder }

        let(:params) do
          {
            correspondence_type: 'foi',
            case_foi: {
              type: 'Standard',
              requester_type: 'member_of_the_public',
              name: 'A. Member of Public',
              postal_address: '102 Petty France',
              email: 'member@public.com',
              subject: 'Responders cannot create cases',
              message: 'I am a responder attempting to create a case',
              received_date_dd: Time.zone.today.day.to_s,
              received_date_mm: Time.zone.today.month.to_s,
              received_date_yyyy: Time.zone.today.year.to_s
            }
          }
        end

        subject { post :create, params: params }

        it 'does not create a new case' do
          expect{ subject }.not_to change { Case::Base.count }
        end

        it 'redirects to the application root path' do
          expect(subject).to redirect_to(responder_root_path)
        end
      end

      context "as an authenticated manager" do
        before do
          sign_in manager
          find_or_create :team_dacu
          find_or_create :team_dacu_disclosure
        end

        context 'with valid params' do
          let(:params) do
            {
              correspondence_type: 'foi',
              case_foi: {
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

          let(:created_case) { Case::Base.first }

          it 'makes a DB entry' do
            expect { post :create, params: params }.
              to change { Case::Base.count }.by 1
          end

          it 'uses the params provided' do
            post :create, params: params

            expect(created_case.requester_type).to eq 'member_of_the_public'
            expect(created_case.type).to eq 'Case::FOI::Standard'
            expect(created_case.name).to eq 'A. Member of Public'
            expect(created_case.postal_address).to eq '102 Petty France'
            expect(created_case.email).to eq 'member@public.com'
            expect(created_case.subject).to eq 'FOI request from controller spec'
            expect(created_case.message).to eq 'FOI about prisons and probation'
            expect(created_case.received_date).to eq Time.zone.today
          end

          it "create a internal review for timeliness" do
            params[:case_foi][:type] = 'TimelinessReview'
            post :create, params: params
            expect(created_case.type).to eq 'Case::FOI::TimelinessReview'
          end

          it "create a internal review for compliance" do
            params[:case_foi][:type] = 'ComplianceReview'
            post :create, params: params
            expect(created_case.type).to eq 'Case::FOI::ComplianceReview'
          end

          describe 'flag_for_clearance' do
            let!(:service) do
              double(CaseFlagForClearanceService, call: true).tap do |svc|
                allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
              end
            end

            it 'does not flag for clearance if parameter is not set' do
              params[:case_foi].delete(:flag_for_disclosure_specialists)
              expect { post :create, params: params }
                .not_to change { Case::Base.count }
              expect(service).not_to have_received(:call)
            end

            it "returns an error message if parameter is not set" do
              params[:case_foi].delete(:flag_for_disclosure_specialists)
              post :create, params: params
              expect(assigns(:case).errors).to have_key(:flag_for_disclosure_specialists)
              expect(response).to have_rendered(:new)
            end

            it "flags the case for clearance if parameter is true" do
              params[:case_foi][:flag_for_disclosure_specialists] = 'yes'
              post :create, params: params
              expect(service).to have_received(:call)
            end

            it "does not flag the case for clearance if parameter is false" do
              params[:case_foi][:flag_for_disclosure_specialists] = false
              post :create, params: params
              expect(service).not_to have_received(:call)
            end
          end
        end
      end
    end

    context 'ICO case' do
      let(:params) do
        {
          correspondence_type: 'ico',
          case_foi: {
            original_request_type: 'FOI',
            ico_reference_number: 'ICOREF1',
            subject: 'ICO appeal for an FOI subject',
            message: 'ICO appeal for an FOI message',
            received_date_dd: Time.zone.today.day.to_s,
            received_date_mm: Time.zone.today.month.to_s,
            received_date_yyyy: Time.zone.today.year.to_s,
            external_deadline_dd: 20.business_days.from_now.day.to_s,
            external_deadline_mm: 20.business_days.from_now.month.to_s,
            external_deadline_yyyy: 20.business_days.from_now.year.to_s,
            uploaded_request_files: ['uploads/71/request/request.pdf'],
          }
        }
      end

      describe 'authentication' do
        subject { get :create, params: params }

        it 'authorises with can_add_case? policy and Case::ICO::Base' do
          sign_in manager
          expect{ subject }.to require_permission(:can_add_case?)
                                 .with_args(manager, Case::ICO::Base)
        end

        it 'does not create a case when authentication fails' do
          sign_in responder
          expect{ subject }.not_to change { Case::Base.count }
        end

        it 'redirects to the application root path when authentication fails' do
          sign_in responder
          expect(subject).to redirect_to(responder_root_path)
        end
      end

      describe 'creating an ICO case' do
        before do
          sign_in manager
          find_or_create :team_dacu
          find_or_create :team_dacu_disclosure
        end

        let(:created_case) { Case::Base.first }

        it 'makes a DB entry' do
          expect { post :create, params: params }.
            to change { Case::ICO::FOI.count }.by 1
        end

        it 'uses the params provided' do
          post :create, params: params

          created_case = Case::ICO::FOI.last
          expect(created_case.type).to eq 'Case::ICO::FOI'
          expect(created_case.ico_reference_number).to eq 'ICOREF1'
          expect(created_case.subject).to eq 'ICO appeal for an FOI subject'
          expect(created_case.message).to eq 'ICO appeal for an FOI message'
          expect(created_case.received_date).to eq Time.zone.today
          expect(created_case.external_deadline).to eq 20.business_days.from_now.day.to_s
        end
      end
    end
  end
end
