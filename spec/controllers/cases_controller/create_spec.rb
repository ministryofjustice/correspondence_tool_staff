require 'rails_helper'

describe CasesController do
  let(:manager)               { create :manager }
  let(:responder)             { create :responder }
  let(:foi_params) do
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
  let(:foi_case_for_ico) { create :closed_case }
  let(:ico_params) do
    {
      correspondence_type: 'ico',
      case_ico: {
        original_case_id: foi_case_for_ico.id,
        ico_officer_name: 'Ian C. Oldman',
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

  describe 'POST create' do
    describe 'cross-correspondence-type functionality' do
      before do
        sign_in manager
        find_or_create :team_dacu
      end

      it 'assigns @correspondence_type' do
        post :create, params: foi_params

        expect(assigns(:correspondence_type)).to eq CorrespondenceType.foi
      end

      it 'assigns @correspondence_type' do
        post :create, params: foi_params

        expect(assigns(:correspondence_type_key))
          .to eq 'foi'
      end
    end

    context 'FOI case' do
      describe 'authentication' do
        subject { post :create, params: foi_params }

        it 'authorises with can_add_case? policy and Case::ICO::Base' do
          sign_in manager
          expect{ subject }.to require_permission(:can_add_case?)
                                 .with_args(manager, Case::FOI::Standard)
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

      context "as an authenticated manager" do
        before do
          sign_in manager
          find_or_create :team_dacu
          find_or_create :team_dacu_disclosure
        end

        let(:created_case) { Case::Base.first }

        it 'makes a DB entry' do
          expect { post :create, params: foi_params }.
            to change { Case::Base.count }.by 1
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
        end

        it 'diplays a flash message' do
          post :create, params: foi_params
          expect(flash[:notice]).to eq "FOI case created<br/>Case number: #{created_case.number}"
        end

        it "create a internal review for timeliness" do
          foi_params[:case_foi][:type] = 'TimelinessReview'
          post :create, params: foi_params
          expect(created_case.type).to eq 'Case::FOI::TimelinessReview'
        end

        it "create a internal review for compliance" do
          foi_params[:case_foi][:type] = 'ComplianceReview'
          post :create, params: foi_params
          expect(created_case.type).to eq 'Case::FOI::ComplianceReview'
        end

        describe 'flag_for_clearance' do
          let!(:service) do
            double(CaseFlagForClearanceService, call: true).tap do |svc|
              allow(CaseFlagForClearanceService).to receive(:new).and_return(svc)
            end
          end

          it 'does not flag for clearance if parameter is not set' do
            foi_params[:case_foi].delete(:flag_for_disclosure_specialists)
            expect { post :create, params: foi_params }
              .not_to change { Case::Base.count }
            expect(service).not_to have_received(:call)
          end

          it "returns an error message if parameter is not set" do
            foi_params[:case_foi].delete(:flag_for_disclosure_specialists)
            post :create, params: foi_params
            expect(assigns(:case).errors).to have_key(:flag_for_disclosure_specialists)
            expect(response).to have_rendered(:new)
          end

          it "flags the case for clearance if parameter is true" do
            foi_params[:case_foi][:flag_for_disclosure_specialists] = 'yes'
            post :create, params: foi_params
            expect(service).to have_received(:call)
          end

          it "does not flag the case for clearance if parameter is false" do
            foi_params[:case_foi][:flag_for_disclosure_specialists] = false
            post :create, params: foi_params
            expect(service).not_to have_received(:call)
          end
        end

        context 'type not set' do
          let(:invalid_foi_params) {
            foi_params.tap do |p|
              p[:case_foi][:type] = nil
            end
          }

          before do
            sign_in manager
            find_or_create :team_dacu
            find_or_create :team_dacu_disclosure
          end

          it 're-renders new page' do
            post :create, params: invalid_foi_params

            expect(response).to have_rendered(:new)
            expect(assigns(:case_types)).to eq ['Case::FOI::Standard',
                                                'Case::FOI::TimelinessReview',
                                                'Case::FOI::ComplianceReview',]
            expect(assigns(:case)).to be_an_instance_of(Case::FOI::Standard)
            expect(assigns(:s3_direct_post)).to be_present
          end
        end      end
    end

    context 'ICO case' do
      describe 'authentication' do
        subject { post :create, params: ico_params }

        it 'authorises with can_add_case? policy and Case::ICO::Base' do
          sign_in manager
          expect{ subject }.to require_permission(:can_add_case?)
                                 .with_args(manager, Case::ICO::FOI)
        end

        it 'does not create a case when authentication fails' do
          sign_in responder
          foi_case_for_ico
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

        let(:created_case) { Case::Base.last }

        it 'makes a DB entry' do
          expect { post :create, params: ico_params }.
            to change { Case::ICO::FOI.count }.by 1
        end

        it 'uses the params provided' do
          post :create, params: ico_params

          created_case = Case::ICO::FOI.last
          expect(created_case.type).to eq 'Case::ICO::FOI'
          expect(created_case.ico_reference_number).to eq 'ICOREF1'
          expect(created_case.ico_officer_name).to eq 'Ian C. Oldman'
          expect(created_case.subject).to eq 'ICO appeal for an FOI subject'
          expect(created_case.message).to eq 'ICO appeal for an FOI message'
          expect(created_case.received_date).to eq Time.zone.today
          expect(created_case.external_deadline).to eq 20.business_days.from_now.to_date
        end

        it 'diplays a flash message' do
          post :create, params: ico_params
          expect(flash[:notice]).to eq "ICO case created<br/>Case number: #{created_case.number}"
        end

        context 'original case not linked' do
          let(:invalid_ico_params) {
            ico_params.tap do |p|
              p[:case_ico].delete(:original_case_id)
            end
          }

          before do
            sign_in manager
            find_or_create :team_dacu
            find_or_create :team_dacu_disclosure
          end

          it 're-renders new page' do
            post :create, params: invalid_ico_params

            expect(response).to have_rendered(:new)
            expect(assigns(:case_types)).to eq ['Case::ICO::FOI',
                                                'Case::ICO::SAR',]
            expect(assigns(:case)).to be_an_instance_of(Case::ICO::FOI)
            expect(assigns(:s3_direct_post)).to be_present
          end
        end
      end
    end
  end
end
