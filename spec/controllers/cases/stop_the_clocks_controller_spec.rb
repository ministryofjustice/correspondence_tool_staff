require "rails_helper"

describe Cases::StopTheClocksController, type: :controller do
  let(:manager)     { find_or_create :disclosure_bmt_user }
  let(:approver)    { find_or_create :approver }
  let(:team_admin)  { find_or_create :team_admin }
  let(:responder)   { find_or_create :responder }
  let(:sar_case)    { create :sar_case }

  let(:service) do
    instance_double(CaseStopTheClockService, call: :ok, result: :ok)
  end

  let(:post_params) do
    {
      case_id: sar_case.id,
      case: {
        stop_the_clock_categories: [
          "To clarify something - CCTV or BWCF requirements",
          "Something else - Another reason",
        ],
        stop_the_clock_date_dd: "10",
        stop_the_clock_date_mm: "8",
        stop_the_clock_date_yyyy: "2025",
        stop_the_clock_reason: "need more time",
      },
    }
  end

  before do
    sign_in user
  end

  describe "#new" do
    subject(:response) { get :new, params: { case_id: sar_case.id } }

    context "when manager" do
      let(:user) { manager }

      it { is_expected.to have_http_status(:ok) }
    end

    context "when approver" do
      let(:user) { approver }

      it { is_expected.to have_http_status(:ok) }
    end

    context "when team_admin" do
      let(:user) { team_admin }

      it { is_expected.to have_http_status(:ok) }
    end

    context "when responder" do
      let(:user) { responder }

      it { is_expected.to have_http_status(:redirect) }
    end
  end

  describe "#create" do
    context "when manager" do
      let(:user) { manager }
      let(:post_params) do
        {
          case_id: sar_case.id,
          case: {
            stop_the_clock_categories: [
              "To clarify something - CCTV or BWCF requirements",
              "Something else - Another reason",
            ],
            stop_the_clock_date_dd: "10",
            stop_the_clock_date_mm: "8",
            stop_the_clock_date_yyyy: "2025",
            stop_the_clock_reason: "need more time",
          },
        }
      end

      before do
        allow(CaseStopTheClockService).to receive(:new).and_return(service)
        sign_in user
      end

      context "with valid params" do
        before do
          post :create, params: post_params
        end

        it "calls the CaseStopTheClockService" do
          expect(CaseStopTheClockService).to have_received(:new)
          expect(service).to have_received(:call)
          expect(request.flash[:notice]).to eq "You have stopped the clock on this case."
        end
      end

      context "with invalid params" do
        let(:service) do
          instance_double(CaseStopTheClockService, call: :validation_error, result: :validation_error)
        end

        it "renders the new page" do
          post :create, params: post_params
          expect(request).to have_rendered(:new)
        end
      end

      context "when failed request" do
        let(:service) do
          instance_double(CaseStopTheClockService, call: :error, result: :error)
        end

        it "notifies the user of the failure" do
          post :create, params: post_params
          expected_message = "Unable to stop the clock on this case."

          expect(request.flash[:alert]).to eq expected_message
          expect(request).to redirect_to(case_path(sar_case.id))
        end
      end
    end
  end
end
