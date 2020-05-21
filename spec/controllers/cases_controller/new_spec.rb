require 'rails_helper'

describe CasesController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }

  describe '#select_type' do
    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :new }
        .to require_permission(:can_add_case?).with_args(manager, Case::Base)
    end

    context 'with valid params' do
      before do
        get :new
      end

      it 'renders the select_type template' do
        expect(response).to render_template(:select_type)
      end

      it 'assigns @permitted_correspondence_types' do
        expect(assigns(:permitted_correspondence_types))
          .to match_array [
            CorrespondenceType.foi,
            CorrespondenceType.sar,
            CorrespondenceType.ico
          ]
      end

      # @todo: Does not apply to cases_controller, but to sub-class
      # it 'assigns @s3_direct_post when rendering new case page' do
      #   get :new, params: { correspondence_type: 'foi' }
      #   expect(assigns(:s3_direct_post)).to be_present
      # end
    end
  end
end
