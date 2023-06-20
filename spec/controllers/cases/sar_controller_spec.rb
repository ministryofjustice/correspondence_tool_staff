require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

RSpec.describe Cases::SarController, type: :controller do
  describe "authentication" do
    let(:params) do
      {
        correspondence_type: "sar",
        sar: {
          requester_type: "member_of_the_public",
          type: "Standard",
          name: "A. Member of Public",
          postal_address: "102 Petty France",
          email: "member@public.com",
          subject: "SAR request from controller spec",
          message: "SAR about prisons and probation",
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
          delivery_method: :sent_by_email,
          flag_for_disclosure_specialists: false,
        },
      }
    end

    include_examples "can_add_case policy spec", Case::SAR::Standard
  end

  describe "#new" do
    let(:case_types) { %w[Case::SAR::Standard] }

    let(:params) { { correspondence_type: "sar" } }

    include_examples "new case spec", Case::SAR::Standard
  end

  describe "#edit" do
    let(:kase) { create :sar_case, :flagged_accepted }

    include_examples "edit case spec"
  end

  describe "#update", versioning: true do
    let(:correspondence_type_abbr) { "sar" }
    let(:kase) do
      Timecop.freeze(now) do
        create :accepted_sar,
               name: "Original Name",
               email: "original_email@moj.com",
               message: "origninal full case",
               received_date: now.to_date,
               postal_address: "",
               subject: "Original summary",
               third_party: false,
               reply_method: "send_by_email",
               subject_type: "offender",
               subject_full_name: "original subject"
      end
    end
    let(:params) do
      {
        "correspondence_type" => "sar",
        "sar" => {
          "subject_full_name" => "modified subject",
          "subject_type" => "member_of_the_public",
          "third_party" => "true",
          "name" => "the new requestor",
          "third_party_relationship" => "Aunty",
          "received_date_dd" => "26",
          "received_date_mm" => "5",
          "received_date_yyyy" => "2018",
          "date_draft_compliant_dd" => "28",
          "date_draft_compliant_mm" => "5",
          "date_draft_compliant_yyyy" => "2018",
          "subject" => "modified summary",
          "message" => "moidified full case",
          "flag_for_disclosure_specialists" => "no",
          "reply_method" => "send_by_post",
          "email" => "modified@Moj.com",
          "postal_address" => "modified address",
        },
        "commit" => "Submit",
        "id" => kase.id.to_s,
      }
    end
    let(:valid_params_check) do
      expect(kase.third_party).to be true
      expect(kase.reply_method).to eq "send_by_post"
      expect(kase.subject_type).to eq "member_of_the_public"
      expect(kase.subject_full_name).to eq "modified subject"
    end

    include_examples "update case spec"
  end

  describe "closeable" do
    describe "#edit_closure" do
      context "when SAR case" do
        let(:kase)    { create :closed_sar }
        let(:manager) { find_or_create :disclosure_bmt_user }

        before do
          sign_in manager
        end

        it "authorises with update_closure? policy" do
          expect {
            get :edit_closure, params: { id: kase.id }
          }.to require_permission(:update_closure?)
            .with_args(manager, kase)
        end

        it "renders the close page" do
          get :edit_closure, params: { id: kase.id }
          expect(response).to render_template :edit_closure
        end
      end
    end

    describe "#process_closure" do
      let(:sar) { create :accepted_sar }
      let(:responder) { sar.responder }
      let(:another_responder) { create :responder }

      before(:all) do
        CaseClosure::MetadataSeeder.seed!
      end

      after(:all) do
        CaseClosure::MetadataSeeder.unseed!
      end

      before do
        allow(ActionNotificationsMailer).to receive_message_chain(:notify_team,
                                                                  :deliver_later)
      end

      it "closes a case that has been responded to" do
        sign_in responder
        patch :process_respond_and_close, params: sar_closure_params(sar)
        expect(Case::SAR::Standard.first.current_state).to eq "closed"
        expect(Case::SAR::Standard.first.refusal_reason_id).to eq CaseClosure::RefusalReason.sar_tmm.id
        expect(Case::SAR::Standard.first.date_responded).to eq 3.days.ago.to_date
        expect(ActionNotificationsMailer)
          .to have_received(:notify_team)
            .with(sar.managing_team, sar, "Case closed")
      end

      context "when not the assigned responder" do
        it "does not progress the case" do
          sign_in another_responder
          patch :process_respond_and_close, params: sar_closure_params(sar)
          expect(Case::SAR::Standard.first.current_state).to eq "drafting"
          expect(Case::SAR::Standard.first.date_responded).to be nil
          expect(ActionNotificationsMailer)
            .not_to have_received(:notify_team)
              .with(sar.managing_team, sar, "Case closed")
        end
      end

      def sar_closure_params(sar)
        date_responded = 3.days.ago
        {
          id: sar.id,
          sar: {
            date_responded_dd: date_responded.day,
            date_responded_mm: date_responded.month,
            date_responded_yyyy: date_responded.year,
            missing_info: "yes",
          },
        }
      end
    end

    describe "#update_closure" do
      before(:all) do
        CaseClosure::MetadataSeeder.seed!
      end

      after(:all) do
        DbHousekeeping.clean
      end

      let(:responder) { create :foi_responder }
      let(:manager)   { find_or_create :disclosure_bmt_user }
      let(:new_date_responded) { 1.business_day.before(kase.date_responded) }
      let(:params)             do
        {
          id: kase.id,
          sar: {
            date_responded_yyyy: new_date_responded.year,
            date_responded_mm: new_date_responded.month,
            date_responded_dd: new_date_responded.day,
            missing_info: "yes",
          },
        }
      end

      context "when closed" do
        context "when a manager" do
          let(:kase) { create :closed_sar }

          before do
            sign_in manager
            patch :update_closure, params:
          end

          it "updates the cases date responded field" do
            kase.reload
            expect(kase.date_responded).to eq new_date_responded
          end

          it "updates the cases refusal reason" do
            kase.reload
            expect(kase.refusal_reason).to eq CaseClosure::RefusalReason.sar_tmm
          end

          it "redirects to the case details page" do
            expect(response).to redirect_to case_path(id: kase.id)
          end
        end

        context "when a responder" do
          let(:kase) { create :closed_sar, responder: }

          before do
            sign_in manager
            patch :update_closure, params:
          end

          it "updates the cases date responded field" do
            # TODO: out-of-business-hours failure here.
            kase.reload
            expect(kase.date_responded).to eq new_date_responded
          end

          it "updates the cases refusal reason" do
            kase.reload
            expect(kase.refusal_reason).to eq CaseClosure::RefusalReason.sar_tmm
          end

          it "redirects to the case details page" do
            expect(response).to redirect_to case_path(id: kase.id)
          end
        end
      end

      context "when open" do
        before do
          sign_in manager
          patch :update_closure, params:
        end

        let(:new_date_responded) { 1.business_day.ago }
        let(:kase)               { create :sar_case }

        it "does not change the date responded" do
          kase.reload
          expect(kase.date_responded).not_to eq new_date_responded
        end

        it "does not update the cases refusal reason" do
          kase.reload
          expect(kase.refusal_reason).to be_nil
        end

        it "redirects to the case details page" do
          expect(response).to redirect_to case_path(id: kase.id)
        end
      end
    end
  end
end
