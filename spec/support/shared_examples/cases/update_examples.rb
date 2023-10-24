require "rails_helper"

RSpec.shared_examples "update case spec" do
  let(:now) { Time.zone.local(2018, 5, 30, 10, 23, 33) }

  context "when a manager" do
    before do
      sign_in manager
    end

    let(:manager) { find_or_create :disclosure_bmt_user }
    let(:received_date) do
      Date.new(
        params[correspondence_type_abbr]["received_date_yyyy"].to_i,
        params[correspondence_type_abbr]["received_date_mm"].to_i,
        params[correspondence_type_abbr]["received_date_dd"].to_i,
      )
    end
    let(:date_draft_compliant) do
      Date.new(
        params[correspondence_type_abbr]["date_draft_compliant_yyyy"].to_i,
        params[correspondence_type_abbr]["date_draft_compliant_mm"].to_i,
        params[correspondence_type_abbr]["date_draft_compliant_dd"].to_i,
      )
    end

    context "with valid params" do
      it "updates the case" do
        Timecop.freeze(now) do
          patch(:update, params:)
          expect(response).to redirect_to case_path(kase.id)
          expect(flash[:notice]).to eq "Case updated"

          kase.reload
          kase.versions.reload

          expect(kase.name).to eq params[correspondence_type_abbr]["name"]
          expect(kase.email).to eq params[correspondence_type_abbr]["email"]
          expect(kase.message).to eq params[correspondence_type_abbr]["message"]
          expect(kase.received_date).to eq received_date
          expect(kase.postal_address).to eq params[correspondence_type_abbr]["postal_address"]
          expect(kase.subject).to eq params[correspondence_type_abbr]["subject"]
          expect(kase.date_draft_compliant).to eq date_draft_compliant

          expect(kase.versions.size).to eq 2
          expect(kase.versions.last.whodunnit).to eq manager.id.to_s

          # Bespoke params check (set in controller spec)
          valid_params_check
        end
      end
    end

    context "with invalid params" do
      context "and received_date too far into past" do
        before { params[correspondence_type_abbr]["received_date_yyyy"] = "2017" }

        it "does not update the record" do
          Timecop.freeze(now) do
            original_kase = kase.clone
            patch(:update, params:)
            expect(kase.reload).to eq original_kase
          end
        end

        it "has error details on the record" do
          patch(:update, params:)
          expect(assigns(:case).errors.full_messages).to eq ["Received date too far in past."]
        end

        it "redisplays the edit page" do
          patch(:update, params:)
          expect(response).to render_template :edit
        end
      end

      context "when date draft compliant before received date" do
        it "has error details on the record" do
          Timecop.freeze(now) do
            kase.date_responded = 3.working.days.after(kase.received_date)
            params[correspondence_type_abbr]["date_draft_compliant_yyyy"] = "2016"
            patch(:update, params:)
            expect(assigns(:case).errors.full_messages).to eq ["Date compliant draft uploaded cannot be before date received"]
          end
        end
      end

      context "when date draft compliant in future" do
        it "has error details on the record" do
          Timecop.freeze(now) do
            params[correspondence_type_abbr]["date_draft_compliant_yyyy"] = "2020"
            patch(:update, params:)
            expect(assigns(:case).errors.full_messages).to eq ["Date compliant draft uploaded cannot be in the future."]
          end
        end
      end
    end
  end

  context "when a non-manager" do
    let(:responder) { find_or_create :foi_responder }

    before do
      Timecop.freeze(now) do
        sign_in responder
        patch :update, params:
      end
    end

    it "redirects" do
      Timecop.freeze(now) do
        expect(response).to redirect_to root_path
      end
    end

    it "gives error in flash" do
      Timecop.freeze(now) do
        expect(flash[:alert]).to eq "You are not authorised to edit this case."
      end
    end
  end
end
