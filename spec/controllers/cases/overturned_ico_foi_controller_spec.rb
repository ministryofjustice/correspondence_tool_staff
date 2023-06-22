require "rails_helper"

RSpec.describe Cases::OverturnedIcoFoiController, type: :controller do
  describe "#new" do
    let(:manager) { create :manager }

    before do
      sign_in manager
    end

    describe "authorization" do
      let(:kase) { create :ico_foi_case }
      let(:decorator) { Case::OverturnedICO::FOIDecorator }
      let(:ico_decorator) { Case::ICO::FOIDecorator }
      let(:abbreviation) { "OVERTURNED_FOI" }

      include_examples "new overturned ico spec", Case::OverturnedICO::FOI
    end
  end

  describe "#create" do
    let(:deadline) { 1.month.ago }
    let(:manager) { create :manager }
    let(:received_date) { Time.zone.today }

    let(:ico_overturned_foi_params) do
      {
        overturned_foi: {
          email: "stephen@stephenrichards.eu",
          external_deadline_dd: deadline.day.to_s,
          external_deadline_mm: deadline.month.to_s,
          external_deadline_yyyy: deadline.year.to_s,
          original_ico_appeal_id: ico_foi_case.id.to_s,
          received_date_dd: received_date.day.to_s,
          received_date_mm: received_date.month.to_s,
          received_date_yyyy: received_date.year.to_s,
        },
        correspondence_type: "overturned_foi",
      }
    end

    let(:foi) { create :foi_case }

    let(:ico_foi_case) do
      create(
        :ico_foi_case,
        original_case: foi,
        date_ico_decision_received: Time.zone.today
      )
    end

    let(:controller_params) do
      ActionController::Parameters
        .new(ico_overturned_foi_params)
        .require(:overturned_foi)
    end

    let(:new_overturned_case) do
      double Case::OverturnedICO::FOI, id: 87_366
    end

    let(:decorated_overturned_case) do
      double(Case::OverturnedICO::FOIDecorator, uploads_dir: "xx")
    end

    let!(:service) do
      double(
        CaseCreateService,
        user: manager,
        params: controller_params,
        case: new_overturned_case,
        case_type: Case::OverturnedICO::FOI,
        call: nil,
        message: "Case successfully created"
      )
    end

    before do
      sign_in manager

      params = ActionController::Parameters.new(ico_overturned_foi_params)
        .require(:overturned_foi)
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
          ]
        )
        .merge(original_case_id: foi.id)

      expect(CaseCreateService).to receive(:new).with(
        user: manager,
        case_type: Case::OverturnedICO::FOI,
        params:,
      ).and_return(service)
    end

    context "with valid params" do
      before do
        expect(service).to receive(:result).and_return(:assign_responder)
        expect(service).to receive(:message).and_return("Case successfully created")
        post :create, params: ico_overturned_foi_params
      end

      it "sets the flash" do
        expect(flash[:creating_case]).to be true
        expect(flash[:notice]).to eq "Case successfully created"
      end

      it "redirects to the new case assignment page" do
        expect(response)
          .to redirect_to(new_case_assignment_path(new_overturned_case))
      end
    end

    context "with invalid params" do
      before do
        expect(service).to receive(:result).and_return(:error)
        expect(new_overturned_case)
          .to receive(:decorate).and_return(decorated_overturned_case)
      end

      it "renders the new page" do
        post :create, params: ico_overturned_foi_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe "closeable" do
    describe "#confirm_respond" do
      let(:case_with_response) { create :case_with_response }
      let(:responder) { case_with_response.responder }
      let(:responding_team) { case_with_response.responding_team }
      let(:ot_foi) do
        create(
          :with_response_ot_ico_foi,
          responder:,
          responding_team:
        )
      end
      let(:date_responded) { ot_foi.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: "overturned_ico_foi",
          overturned_foi: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
          },
          commit: "Mark response as sent",
          id: ot_foi.id.to_s,
        }
      end

      context "with the assigned responder" do
        before { sign_in responder }

        it 'transitions current_state to "responded"' do
          stub_find_case(ot_foi.id) do |kase|
            expect(kase).to receive(:respond).with(responder)
          end
          patch :confirm_respond, params:
        end

        it "redirects to the case list view" do
          expect(patch(:confirm_respond, params:)).to redirect_to(case_path(ot_foi))
        end

        context "with invalid params" do
          let(:params) do
            {
              correspondence_type: "overturned_ico_foi",
              overturned_foi: {
                date_responded_dd: "",
                date_responded_mm: "",
                date_responded_yyyy: "",
              },
              commit: "Mark response as sent",
              id: ot_foi.id.to_s,
            }
          end

          it "redirects to the respond page" do
            expect(patch(:confirm_respond, params:))
            expect(response).to render_template(:respond)
          end
        end
      end
    end
  end
end
