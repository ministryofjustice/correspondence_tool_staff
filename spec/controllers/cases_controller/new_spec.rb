require "rails_helper"

describe CasesController, type: :controller do # rubocop:disable RSpec/FilePath
  describe "#select_type" do
    context "when a manager" do
      let(:manager) { find_or_create :disclosure_bmt_user }

      before do
        sign_in manager
      end

      it "authorizes" do
        expect { get :new }
          .to require_permission(:can_add_case?).with_args(manager, Case::Base)
      end

      context "with valid params" do
        before do
          get :new
        end

        it "renders the select_type template" do
          expect(response).to render_template(:select_type)
        end

        it "assigns @permitted_correspondence_types" do
          expect(assigns(:permitted_correspondence_types))
            .to match_array [
              CorrespondenceType.foi,
              CorrespondenceType.sar,
              CorrespondenceType.sar_internal_review,
              CorrespondenceType.ico,
            ]
          expect(assigns(:permitted_correspondence_types))
            .not_to include CorrespondenceType.offender_sar
        end

        # @todo: Does not apply to cases_controller, but to sub-class
        # it 'assigns @s3_direct_post when rendering new case page' do
        #   get :new, params: { correspondence_type: 'foi' }
        #   expect(assigns(:s3_direct_post)).to be_present
        # end
      end
    end

    context "when a responder" do
      let(:responder) { find_or_create :branston_user }

      before do
        sign_in responder
      end

      it "authorizes" do
        expect { get :new }
          .to require_permission(:can_add_case?).with_args(responder, Case::Base)
      end

      context "with valid params" do
        before do
          get :new
        end

        it "renders the offender_sar_select_type template" do
          expect(response).to render_template(:offender_sar_select_type)
        end

        it "assigns @permitted_correspondence_types" do
          expect(assigns(:permitted_correspondence_types))
            .to match_array [
              CorrespondenceType.offender_sar,
              CorrespondenceType.offender_sar_complaint,
            ]
          expect(assigns(:permitted_correspondence_types))
            .not_to include CorrespondenceType.foi
          expect(assigns(:permitted_correspondence_types))
            .not_to include CorrespondenceType.sar
          expect(assigns(:permitted_correspondence_types))
          .not_to include CorrespondenceType.ico
        end

        # @todo: Does not apply to cases_controller, but to sub-class
        # it 'assigns @s3_direct_post when rendering new case page' do
        #   get :new, params: { correspondence_type: 'foi' }
        #   expect(assigns(:s3_direct_post)).to be_present
        # end
      end
    end
  end
end
