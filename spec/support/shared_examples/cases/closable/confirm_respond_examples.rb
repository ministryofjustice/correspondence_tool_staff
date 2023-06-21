require "rails_helper"

RSpec.shared_examples "confirm respond spec" do |klass|
  describe klass, type: :controller do
    let(:responder)          { kase.responder }
    let(:another_responder)  { create :responder }
    let(:manager)            { find_or_create :disclosure_bmt_user }

    context "with case" do
      let(:date_responded) { kase.received_date + 2.days }
      let(:params) do
        {
          correspondence_type: "foi",
          foi: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
          },
          commit: "Mark response as sent",
          id: kase.id.to_s,
        }
      end

      context "when an anonymous user" do
        it "redirects to sign_in" do
          expect(patch(:confirm_respond, params:)).to redirect_to(new_user_session_path)
        end

        it "does not transition current_state" do
          expect(kase.current_state).to eq "awaiting_dispatch"
          patch(:confirm_respond, params:)
          expect(kase.current_state).to eq "awaiting_dispatch"
        end
      end

      context "when an authenticated manager" do
        before { sign_in manager }

        it "redirects to the application root" do
          expect(patch(:confirm_respond, params:)).to redirect_to(manager_root_path)
        end

        it "does not transition current_state" do
          expect(kase.current_state).to eq "awaiting_dispatch"
          patch(:confirm_respond, params:)
          expect(kase.current_state).to eq "awaiting_dispatch"
        end
      end

      context "as the assigned responder" do
        before { sign_in responder }

        it 'transitions current_state to "responded"' do
          stub_find_case(kase.id) do |kase|
            expect(kase).to receive(:respond).with(responder)
          end
          patch :confirm_respond, params:
        end

        it "redirects to the case list view" do
          expect(patch(:confirm_respond, params:)).to redirect_to(case_path(kase))
        end

        context "with invalid params" do
          let(:params) do
            {
              correspondence_type: "foi",
              foi: {
                date_responded_dd: "",
                date_responded_mm: "",
                date_responded_yyyy: "",
              },
              commit: "Mark response as sent",
              id: kase.id.to_s,
            }
          end

          it "redirects to the respond page" do
            patch(:confirm_respond, params:)
            expect(response).to render_template(:respond)
          end
        end
      end

      context "when another responder" do
        before { sign_in another_responder }

        it "redirects to the application root" do
          expect(patch(:confirm_respond, params:)).to redirect_to(responder_root_path)
        end

        it "does not transition current_state" do
          expect(kase.current_state).to eq "awaiting_dispatch"
          patch(:confirm_respond, params:)
          expect(kase.current_state).to eq "awaiting_dispatch"
        end
      end
    end
  end
end
