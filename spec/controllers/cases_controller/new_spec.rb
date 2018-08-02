require "rails_helper"

describe CasesController, type: :controller do

  let(:manager) { create :disclosure_bmt_user }

  describe '#new' do


    context 'selecting case type' do
      before do
        sign_in manager
      end

      it 'authorizes' do
        expect { get :new }
          .to require_permission(:can_add_case?)
                .with_args(manager, Case::Base)
      end

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:select_type)
      end

      it 'assigns @permitted_correspondence_types' do
        get :new
        expect(assigns(:permitted_correspondence_types))
          .to match_array [CorrespondenceType.foi,
                           CorrespondenceType.sar,
                           CorrespondenceType.ico]
      end
    end

    it 'assigns @s3_direct_post when rendering new case page' do
      sign_in manager
      get :new, params: { correspondence_type: 'foi' }
      expect(assigns(:s3_direct_post)).to be_present
    end

    context 'new foi case' do
      let(:params) { { correspondence_type: 'foi' } }

      before do
        sign_in manager
      end

      it 'authorizes' do
        sign_in manager

        expect { get :new, params: params }
          .to require_permission(:can_add_case?)
                .with_args(manager, Case::FOI::Standard)
      end

      it 'renders the new template' do
        get :new, params: params
        expect(response).to render_template(:new)
      end

      it 'assigns @case' do
        get :new, params: params
        expect(assigns(:case)).to be_a Case::FOI::Standard
      end

      it 'assigns @case_types' do
        get :new, params: params
        expect(assigns(:case_types)).to eq %w[Case::FOI::Standard
                                              Case::FOI::TimelinessReview
                                              Case::FOI::ComplianceReview]
      end

      it 'assigns @correspondence_type' do
        get :new, params: params
        expect(assigns(:correspondence_type)).to eq CorrespondenceType.foi
      end
    end

    context 'new ico case' do
      let(:params) { { correspondence_type: 'ico' } }

      before do
        sign_in manager
      end

      it 'authorizes' do
        expect { get :new, params: params }
          .to require_permission(:can_add_case?)
                .with_args(manager, Case::ICO::FOI)
      end

      it 'renders the new template' do
        get :new, params: params
        expect(response).to render_template(:new)
      end

      it 'assigns @case' do
        get :new, params: params
        expect(assigns(:case)).to be_a Case::ICO::Base
      end

      it 'assigns @correspondence_type' do
        get :new, params: params
        expect(assigns(:correspondence_type)).to eq CorrespondenceType.ico
      end
    end
  end

  describe '#new_overturned_ico' do
    let(:ico_sar)     { create :ico_sar_case }
    let(:ico_foi)     { create :ico_foi_case }

    before do
      sign_in manager
    end

    context 'authorization' do
      context 'original appeal is Case::ICO::SAR' do
        it 'authorizes' do
          expect { get :new_overturned_ico, params: {id: ico_sar.id} }
              .to require_permission(:new_overturned_ico?)
                      .with_args(manager, Case::OverturnedICO::SAR)
        end
      end

      context 'original appeal is Case::ICO::FOI' do
        it 'authorizes' do
          expect { get :new_overturned_ico, params: {id: ico_foi.id} }
              .to require_permission(:new_overturned_ico?)
                      .with_args(manager, Case::OverturnedICO::FOI)
        end
      end

      context 'original appeal is not an ICO' do
        it 'raises' do
          kase = create :case
          expect {
            get :new_overturned_ico, params: {id: kase}
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    context 'post-authorization processing' do

      let(:service)                   { double CreateOverturnedICOCaseService }

      before(:each) do
        expect(CreateOverturnedICOCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)
        expect(service).to receive(:call)
        expect(service).to receive(:original_ico_appeal).and_return(ico_sar)
      end

      context 'successful case creation' do
        let(:decorated_overturned_ico)  { double Case::OverturnedICO::SARDecorator }
        let(:overturned_ico)            { double Case::OverturnedICO::SAR, decorate: decorated_overturned_ico }

        before(:each) do
          expect(service).to receive(:error?).and_return(false)
          expect(service).to receive(:overturned_ico_case).and_return(overturned_ico)
          get :new_overturned_ico, params: {id: ico_sar.id}
        end

        it 'assigns @case from the case creation service'  do
          expect(assigns(:case)).to eq decorated_overturned_ico
        end

        it 'assigns the original_ico_appeal from the case creation service' do
          expect(assigns(:original_ico_appeal)).to eq ico_sar
        end

        it 'renders the new template' do
          expect(response).to render_template('cases/overturned_ico/new')
        end

        it 'has a status of success' do
          expect(response).to have_http_status(:success)
        end
      end


      context 'unsuccessful case creation' do

        let(:decorated_ico_appeal)    { double Case::ICO::SARDecorator }

        before(:each) do
          expect(service).to receive(:error?).and_return(true)
          expect(ico_sar).to receive(:decorate).and_return(decorated_ico_appeal)
          get :new_overturned_ico, params: {id: ico_sar.id}
        end

        it 'assigns @case from the service original ico appeal' do
          expect(assigns(:case)).to eq decorated_ico_appeal
        end

        it 'renders the show page' do
          expect(response).to render_template(:show)
        end

        it 'has a status of bad request' do
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

  end
end
