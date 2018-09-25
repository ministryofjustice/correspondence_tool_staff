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
  let(:ico_received_date)     { 0.business_days.ago }
  let(:ico_external_deadline) { 20.business_days.after(ico_received_date) }
  let(:ico_internal_deadline) { 10.business_days.before(ico_external_deadline) }
  let(:ico_params) do
    {
      correspondence_type: 'ico',
      case_ico: {
        original_case_id: foi_case_for_ico.id,
        ico_officer_name: 'Ian C. Oldman',
        ico_reference_number: 'ICOREF1',
        message: 'ICO appeal for an FOI message',
        received_date_dd: ico_received_date.day.to_s,
        received_date_mm: ico_received_date.month.to_s,
        received_date_yyyy: ico_received_date.year.to_s,
        internal_deadline_dd: ico_internal_deadline.day.to_s,
        internal_deadline_mm: ico_internal_deadline.month.to_s,
        internal_deadline_yyyy: ico_internal_deadline.year.to_s,
        external_deadline_dd: ico_external_deadline.day.to_s,
        external_deadline_mm: ico_external_deadline.month.to_s,
        external_deadline_yyyy: ico_external_deadline.year.to_s,
        uploaded_request_files: ['uploads/71/request/request.pdf'],
      }
    }
  end
  let(:ico_sar_case)      { create :ico_sar_case }
  let(:ico_foi_case)      { create :ico_foi_case }
  let(:deadline)          { 1.month.ago }
  let(:internal_deadline) { 20.business_days.before(deadline) }

  describe 'POST create' do
    describe 'authentication' do
      let(:user) { create(:user) }
      let(:case_class) { Case::Base }
      let(:service) { instance_spy(CaseCreateService,
                                   case_class: case_class) }

      subject { post :create, params: foi_params }

      before(:each) do
        allow(CaseCreateService).to receive(:new).and_return(service)
      end

      it 'authorises with can_add_case? policy and Case::ICO::Base' do
        sign_in(user)
        expect{ subject }.to require_permission(:can_add_case?)
                               .disallow
                               .with_args(user, case_class)
      end

      it 'does not create a case when authentication fails' do
        disallow_case_policies(case_class, :can_add_case?)
        sign_in user
        expect{ subject }.not_to change { Case::Base.count }
      end

      it 'redirects to the application root path when authentication fails' do
        disallow_case_policies(case_class, :can_add_case?)
        sign_in user
        expect(subject).to redirect_to(responder_root_path)
      end
    end

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
          expect(created_case.subject).to eq foi_case_for_ico.subject
          expect(created_case.message).to eq 'ICO appeal for an FOI message'
          expect(created_case.received_date).to eq ico_received_date.to_date
          expect(created_case.internal_deadline).to eq ico_internal_deadline.to_date
          expect(created_case.external_deadline).to eq ico_external_deadline.to_date
        end

        it 'displays a flash message' do
          post :create, params: ico_params
          expect(flash[:notice]).to eq "ICO appeal (FOI) case created<br/>Case number: #{created_case.number}"
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

    context 'ICO Overturned FOI case' do
      let(:ico_overturned_foi_params) do
        {
          action: 'create',
          case_overturned_foi: {
            email: 'stephen@stephenrichards.eu',
            external_deadline_dd: deadline.day.to_s,
            external_deadline_mm: deadline.month.to_s,
            external_deadline_yyyy: deadline.year.to_s,
            original_ico_appeal_id: ico_foi_case.id.to_s,
            received_date_dd: Date.today.day.to_s,
            received_date_mm: Date.today.month.to_s,
            received_date_yyyy: Date.today.year.to_s,
          },
          controller: 'cases',
          correspondence_type: 'overturned_foi',
        }
      end

      describe 'creating an OverturnedICO::FOI case' do
        let(:correspondence_type)       { CorrespondenceType.foi }
        let(:controller_params)         { ActionController::Parameters
                                            .new(ico_overturned_foi_params) }
        let(:new_overturned_case)       { double Case::OverturnedICO::FOI,
                                                 id: 87366 }
        let(:decorated_overturned_case) { double(Case::OverturnedICO::FOIDecorator,
                                                 uploads_dir: 'xx') }
        let(:service)                   { double(CaseCreateService,
                                             case: new_overturned_case,
                                             case_class: Case::OverturnedICO::FOI,
                                             call: nil) }

        before(:each) do
          sign_in manager
          expect(CaseCreateService).to receive(:new)
                                         .with(manager,
                                               'overturned_foi',
                                               controller_params)
                                         .and_return(service)
        end

        context 'case created OK' do
          before(:each) do
            expect(service).to receive(:result).and_return(:assign_responder)
            expect(service).to receive(:flash_notice)
                                 .and_return('Case successfully created')
            post :create, params: ico_overturned_foi_params
          end

          it 'sets the flash' do
            expect(flash[:creating_case]).to be true
            expect(flash[:notice]).to eq 'Case successfully created'
          end

          it 'redirects to the new case assignment page' do
            expect(response)
              .to redirect_to(new_case_assignment_path(new_overturned_case))
          end
        end

        context 'error when creating case' do
          before(:each) do
            expect(service).to receive(:result).and_return(:error)
            expect(new_overturned_case)
              .to receive(:decorate).and_return(decorated_overturned_case)
          end

          it 'renders the new page' do
            post :create, params: ico_overturned_foi_params
            expect(response).to render_template(:new)
          end
        end
      end

    end

    context 'ICO Overturned SAR case' do
      let(:ico_overturned_sar_params) do
        {
          action: 'create',
          case_overturned_sar: {
            email: 'stephen@stephenrichards.eu',
            external_deadline_dd: deadline.day.to_s,
            external_deadline_mm: deadline.month.to_s,
            external_deadline_yyyy: deadline.year.to_s,
            original_ico_appeal_id: ico_sar_case.id.to_s,
            received_date_dd: Date.today.day.to_s,
            received_date_mm: Date.today.month.to_s,
            received_date_yyyy: Date.today.year.to_s,
          },
          controller: 'cases',
          correspondence_type: 'overturned_sar',
        }
      end

      describe 'creating an OverturnedICO case' do

        before(:each) do
          sign_in manager
          expect(CaseCreateService).to receive(:new).with(manager,
                                                          'overturned_sar',
                                                          controller_params).and_return(service)
        end

        let(:correspondence_type)       { CorrespondenceType.sar }
        let(:controller_params)         { ActionController::Parameters
                                            .new(ico_overturned_sar_params) }
        let(:new_overturned_case)       { double Case::OverturnedICO::SAR, id: 87366 }
        let(:decorated_overturned_case) { double(Case::OverturnedICO::SARDecorator, uploads_dir: 'xx')}
        let(:service)                   { double(CaseCreateService,
                                             case: new_overturned_case,
                                             case_class: Case::OverturnedICO::SAR,
                                             call: nil) }

        context 'case created OK' do
          before(:each) do
            expect(service).to receive(:result).and_return(:assign_responder)
            expect(service).to receive(:flash_notice).and_return('Case successfully created')
            post :create, params: ico_overturned_sar_params
          end

          it 'sets the flash' do
            expect(flash[:creating_case]).to be true
            expect(flash[:notice]).to eq 'Case successfully created'
          end

          it 'redirects to the new case assignment page' do
            expect(response).to redirect_to(new_case_assignment_path(new_overturned_case))
          end
        end

        context 'error when creating case' do
          before(:each) do
            expect(service).to receive(:result).and_return(:error)
            expect(new_overturned_case).to receive(:decorate).and_return(decorated_overturned_case)
          end

          it 'renders the new page' do
            post :create, params: ico_overturned_sar_params
            expect(response).to render_template(:new)
          end
        end
      end

    end
  end
end
