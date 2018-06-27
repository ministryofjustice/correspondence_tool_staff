require "rails_helper"

describe CasesController, type: :controller do
  describe '#new' do
    let(:manager) { create :disclosure_bmt_user }

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

    context 'new foi case' do
      let(:params) { { correspondence_type: 'foi' } }

      before do
        sign_in manager
      end

      it 'authorizes' do
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
    end
  end
end
