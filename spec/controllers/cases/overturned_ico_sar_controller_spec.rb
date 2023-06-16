require "rails_helper"

RSpec.describe Cases::OverturnedIcoSarController, type: :controller do
  let(:manager) { find_or_create :disclosure_specialist_bmt }
  let(:approver) { create :approver }
  let(:sar) { create :sar_case }
  let(:ico_sar) { create :ico_sar_case }

  let(:ico_sar_case) do
    create(
      :ico_sar_case,
      original_case: sar,
      date_ico_decision_received: Date.today,
    )
  end

  let(:original_ico_appeal_case) do
    create(
      :closed_ico_sar_case,
      :overturned_by_ico,
    )
  end

  let(:overturned_ico_case) do
    create(
      :overturned_ico_sar,
      original_ico_appeal: original_ico_appeal_case,
    )
  end

  describe "#new" do
    before { sign_in manager }

    context "with valid params" do
      before do
        service = double(
          NewOverturnedIcoCaseService,
          call: nil,
          error?: false,
          success?: true,
          original_ico_appeal: ico_sar,
          original_case: sar,
          overturned_ico_case:,
        )
        params = ActionController::Parameters.new({ id: ico_sar.id })
        expect(NewOverturnedIcoCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)

        get :new, params: params.to_unsafe_hash
      end

      it "is success" do
        expect(response).to be_successful
      end

      it "assigns a new overturned case to @case" do
        expect(assigns(:case)).to eq overturned_ico_case
      end

      it "renders the new overturned ico case page" do
        expect(response).to render_template("cases/overturned_sar/new")
      end
    end

    context "with invalid params" do
      before do
        service = double(NewOverturnedIcoCaseService,
                         call: nil,
                         error?: true,
                         success?: false,
                         original_ico_appeal: ico_sar,
                         original_case: sar,
                         overturned_ico_case:)
        params = ActionController::Parameters.new({ id: ico_sar.id })
        expect(NewOverturnedIcoCaseService).to receive(:new).with(ico_sar.id.to_s).and_return(service)
        get :new, params: params.to_unsafe_hash
      end

      it "is bad_request" do
        expect(response).to be_bad_request
      end

      it "assigns the original ico appeal to @case" do
        expect(assigns(:case)).to eq ico_sar
      end

      it "renders the show page for the ico appeal" do
        expect(response).to render_template("cases/show")
      end
    end

    context "authorization" do
      let(:kase) { create :ico_sar_case }
      let(:decorator) { Case::OverturnedICO::SARDecorator }
      let(:ico_decorator) { Case::ICO::SARDecorator }
      let(:abbreviation) { "OVERTURNED_SAR" }

      include_examples "new overturned ico spec", Case::OverturnedICO::SAR
    end
  end

  describe "#create" do
    before do
      sign_in manager

      params = ActionController::Parameters.new(ico_overturned_sar_params)
        .require(:overturned_sar)
        .permit(
          %i[
            original_ico_appeal_id
            reply_method
            email
            postal_address
            external_deadline_dd
            external_deadline_mm
            external_deadline_yyyy
            flag_for_disclosure_specialists
            original_case_id
            received_date_dd
            received_date_mm
            received_date_yyyy
          ],
        )
        .merge(original_case_id: sar.id)

      expect(CaseCreateService).to receive(:new).with(
        user: manager,
        case_type: Case::OverturnedICO::SAR,
        params:,
      ).and_return(service)
    end

    let!(:service) do
      double(
        CaseCreateService,
        user: manager,
        params: controller_params,
        case: overturned_ico_case,
        case_type: Case::OverturnedICO::SAR,
        call: nil,
        message: "Case successfully created",
      )
    end

    let(:deadline) { 1.month.ago }
    let(:correspondence_type) { CorrespondenceType.sar }
    let(:decorated_overturned_case) do
      double(Case::OverturnedICO::SARDecorator, uploads_dir: "xx")
    end

    let(:ico_overturned_sar_params) do
      {
        overturned_sar: {
          email: "stephen@stephenrichards.eu",
          external_deadline_dd: deadline.day.to_s,
          external_deadline_mm: deadline.month.to_s,
          external_deadline_yyyy: deadline.year.to_s,
          original_ico_appeal_id: ico_sar_case.id.to_s,
          received_date_dd: Date.today.day.to_s,
          received_date_mm: Date.today.month.to_s,
          received_date_yyyy: Date.today.year.to_s,
        },
        correspondence_type: "overturned_sar",
      }
    end

    let(:controller_params) do
      ActionController::Parameters
        .new(ico_overturned_sar_params)
        .require(:overturned_sar)
    end

    context "with valid params" do
      before do
        expect(service).to receive(:result).and_return(:assign_responder)
        expect(service).to receive(:message).and_return("Case successfully created")
        expect(controller).to be_a described_class
        post :create, params: ico_overturned_sar_params
      end

      it "sets the flash" do
        expect(flash[:creating_case]).to be true
        expect(flash[:notice]).to eq "Case successfully created"
      end

      it "redirects to the new case assignment page" do
        expect(response).to redirect_to(new_case_assignment_path(overturned_ico_case))
      end
    end

    context "with invalid params" do
      before do
        expect(service).to receive(:result).and_return(:error)
        expect(overturned_ico_case).to receive(:decorate).and_return(decorated_overturned_case)
      end

      it "renders the new page" do
        post :create, params: ico_overturned_sar_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe "closeable" do
    before(:all)   do
      @responder = find_or_create :sar_responder
      @drafting_ovt_sar_case = create :accepted_ot_ico_sar, responder: @responder
    end

    after(:all) { DbHousekeeping.clean }

    describe "#respond_and_close" do
      let(:params) { { id: @drafting_ovt_sar_case.id.to_s } }

      context "authorization" do
        it "does not authorize managers" do
          sign_in manager
          get(:respond_and_close, params:)
          expect(flash[:alert]).to eq "You are not authorised to close this case"
          expect(response).to redirect_to root_path
        end

        it "authorizes responders" do
          sign_in @responder
          get(:respond_and_close, params:)
          expect(flash[:alert]).to be_nil
          expect(response).to be_successful
        end

        it "does not authorize approvers" do
          sign_in approver
          get(:respond_and_close, params:)
          expect(flash[:alert]).to eq "You are not authorised to close this case"
          expect(response).to redirect_to root_path
        end
      end

      context "processing" do
        before do
          sign_in @responder
          get :respond_and_close, params:
        end

        it "renders case close" do
          expect(response).to render_template :close
        end

        it "returns success" do
          expect(response).to be_successful
        end

        it "assigns case" do
          expect(assigns(:case)).to eq @drafting_ovt_sar_case
        end
      end
    end

    describe "#process_respond_and_close" do
      let(:params) do
        {
          id: @drafting_ovt_sar_case.id.to_s,
          sar: {
            date_responded_dd: Date.today.day.to_s,
            date_responded_mm: Date.today.month.to_s,
            date_responded_yyyy: Date.today.year.to_s,
            missing_info: "no",
          },
        }
      end

      context "authorization" do
        it "does not authorize managers" do
          sign_in manager
          patch(:process_respond_and_close, params:)
          expect(flash[:alert]).to eq "You are not authorised to close this case"
          expect(response).to redirect_to root_path
        end

        it "authorizes responders" do
          sign_in @responder
          patch(:process_respond_and_close, params:)
          expect(flash[:alert]).to be_nil
          expect(response).to redirect_to case_path(@drafting_ovt_sar_case)
        end

        it "does not authorize approvers" do
          sign_in approver
          patch(:process_respond_and_close, params:)
          expect(flash[:alert]).to eq "You are not authorised to close this case"
          expect(response).to redirect_to root_path
        end
      end

      context "processing" do
        before do
          sign_in @responder
        end

        it "redirects to cases show page" do
          patch(:process_respond_and_close, params:)
          expect(response).to redirect_to case_path(@drafting_ovt_sar_case)
        end

        it "updates case" do
          patch(:process_respond_and_close, params:)
          @drafting_ovt_sar_case.reload
          expect(@drafting_ovt_sar_case.date_responded).to eq Date.today
          expect(@drafting_ovt_sar_case.current_state).to eq "closed"
          expect(@drafting_ovt_sar_case.refusal_reason).to be_nil
        end

        it "displays confirmation message" do
          patch(:process_respond_and_close, params:)
          expect(flash[:notice]).to match(/You've closed this case/)
        end

        context "missing info" do
          it "updates case closure reason with tmm" do
            tmm_refusal_reason = create :refusal_reason, :sar_tmm
            params[:sar][:missing_info] = "yes"
            patch(:process_respond_and_close, params:)
            @drafting_ovt_sar_case.reload
            expect(@drafting_ovt_sar_case.date_responded).to eq Date.today
            expect(@drafting_ovt_sar_case.current_state).to eq "closed"
            expect(@drafting_ovt_sar_case.refusal_reason).to eq tmm_refusal_reason
          end
        end

        context "invalid parameters" do
          it "redisplays error page" do
            params[:sar][:date_responded_dd] = Date.tomorrow.day.to_s
            patch(:process_respond_and_close, params:)
            expect(response).to render_template(:closure_outcomes)
          end
        end
      end
    end
  end
end
