require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
RSpec.describe Cases::ICOController, type: :controller do
  describe "FOI" do
    describe "#edit" do
      let(:kase) { create :accepted_ico_foi_case }

      include_examples "edit case spec"
    end

    describe "#update" do
      let(:manager) { find_or_create :disclosure_bmt_user }
      let(:kase) do
        create :accepted_ico_foi_case
      end
      let(:params) do
        {
          "correspondence_type" => "ico",
          "ico" => {
            "ico_officer_name" => "C00KYM0N",
            "ico_reference_number" => "NEWREFNOMNOMNOM",
            "received_date_dd" => "1",
            "received_date_mm" => "5",
            "received_date_yyyy" => "2018",
            "date_draft_compliant_dd" => "13",
            "date_draft_compliant_mm" => "5",
            "date_draft_compliant_yyyy" => "2018",
            "internal_deadline_dd" => "15",
            "internal_deadline_mm" => "5",
            "internal_deadline_yyyy" => "2018",
            "external_deadline_dd" => "26",
            "external_deadline_mm" => "5",
            "external_deadline_yyyy" => "2018",
            "message" => "modified full request",
          },
          "commit" => "Submit",
          "id" => kase.id.to_s,
        }
      end
      let(:now) { Time.zone.local(2018, 5, 30, 10, 23, 33) }

      before do
        sign_in manager
      end

      context "with valid params" do
        it "updates the case" do
          patch(:update, params:)
          kase.reload

          expect(kase.ico_officer_name).to eq "C00KYM0N"
          expect(kase.ico_reference_number).to eq "NEWREFNOMNOMNOM"
          expect(kase.message).to eq "modified full request"
          expect(kase.received_date).to eq Date.new(2018, 5, 1)
          expect(kase.internal_deadline).to eq Date.new(2018, 5, 15)
          expect(kase.external_deadline).to eq Date.new(2018, 5, 26)
          expect(kase.date_draft_compliant).to eq Date.new(2018, 5, 13)
        end

        it "redirects to show page" do
          patch(:update, params:)
          expect(response).to redirect_to case_path(kase.id)
        end
      end
    end

    describe "closable" do
      describe "#close" do
        let(:kase) { create :responded_ico_foi_case }

        include_examples "close spec", described_class
      end

      describe "#closure_outcomes" do
        let(:kase) { create :responded_ico_foi_case }

        include_examples "closure outcomes spec", described_class
      end

      describe "#edit_closure" do
        let(:kase)    { create :closed_ico_foi_case }
        let(:manager) { find_or_create :disclosure_bmt_user }

        include_examples "edit closure spec", described_class
      end

      describe "#confirm_respond" do
        let(:approver) { find_or_create :disclosure_specialist }
        let(:approved_ico) { create :approved_ico_foi_case }
        let(:date_responded) { approved_ico.received_date + 2.days }
        let(:params) do
          {
            correspondence_type: "ico",
            ico: {
              date_responded_dd: date_responded.day,
              date_responded_mm: date_responded.month,
              date_responded_yyyy: date_responded.year,
            },
            commit: "Submit",
            id: approved_ico.id.to_s,
          }
        end

        context "when the assigned approver" do
          before { sign_in approver }

          it 'transitions current_state to "responded"' do
            stub_find_case(approved_ico.id) do |kase|
              expect(kase).to receive(:respond).with(approver)
            end
            patch :confirm_respond, params:
          end

          it "redirects to the case list view" do
            expect(patch(:confirm_respond, params:)).to redirect_to(case_path(approved_ico))
          end
        end
      end

      describe "#update_closure" do
        before(:all) do
          CaseClosure::MetadataSeeder.seed!
        end

        after(:all) do
          CaseClosure::MetadataSeeder.unseed!
        end

        let(:manager)   { find_or_create :disclosure_bmt_user }
        let(:responder) { create :foi_responder }
        let(:kase) { create :closed_ico_foi_case, :overturned_by_ico }
        let(:new_date_responded) { 1.business_day.before(kase.date_ico_decision_received) }

        context "when closed ICO" do
          context "and change to upheld" do
            let(:params) do
              {
                id: kase.id,
                ico: {
                  date_ico_decision_received_yyyy: kase.created_at.year,
                  date_ico_decision_received_mm: kase.created_at.month,
                  date_ico_decision_received_dd: kase.created_at.day,
                  ico_decision: "upheld",
                  ico_decision_comment: "ayt",
                  uploaded_ico_decision_files: ["uploads/71/request/request.pdf"],
                },
              }
            end

            before do
              sign_in manager
              patch :update_closure, params:
            end

            it "updates the cases date responded field" do
              kase.reload
              expect(kase.date_ico_decision_received).to eq kase.created_at.to_date
            end

            it "updates the cases refusal reason" do
              kase.reload
              expect(kase.ico_decision).to eq "upheld"
            end

            it "redirects to the case details page" do
              expect(response).to redirect_to case_path(id: kase.id)
            end
          end

          context "when no ico decison files specified" do
            let(:params) do
              {
                id: kase.id,
                ico: {
                  date_ico_decision_received_yyyy: kase.created_at.year,
                  date_ico_decision_received_mm: kase.created_at.month,
                  date_ico_decision_received_dd: kase.created_at
                  .day,
                  ico_decision: "upheld",
                  ico_decision_comment: "ayt",
                },
              }
            end

            before do
              sign_in manager
              patch :update_closure, params:
            end

            it "updates the cases date responded field" do
              kase.reload
              expect(kase.date_ico_decision_received).to eq kase.created_at.to_date
            end

            it "updates the cases refusal reason" do
              kase.reload
              expect(kase.ico_decision).to eq "upheld"
            end

            it "redirects to the case details page" do
              expect(response).to redirect_to case_path(id: kase.id)
            end
          end

          context "when change to overturned" do
            let(:kase)         { create :closed_ico_foi_case, date_ico_decision_received: Time.zone.today }
            let(:params)       do
              {
                id: kase.id,
                ico: {
                  date_ico_decision_received_yyyy: new_date_responded.year,
                  date_ico_decision_received_mm: new_date_responded.month,
                  date_ico_decision_received_dd: new_date_responded.day,
                  ico_decision: "overturned",
                  ico_decision_comment: "ayt",
                  uploaded_ico_decision_files: ["uploads/71/request/request.pdf"],
                },
              }
            end

            before do
              sign_in manager
              patch :update_closure, params:
            end

            it "updates the cases date responded field" do
              kase.reload
              expect(kase.date_ico_decision_received).to eq new_date_responded
            end

            it "updates the cases refusal reason" do
              kase.reload
              expect(kase.ico_decision).to eq "overturned"
            end

            it "redirects to the case details page" do
              expect(response).to redirect_to case_path(id: kase.id)
            end
          end
        end

        context "when open ICO" do
          let(:kase) { create :accepted_ico_foi_case }
          let(:new_date_responded) { 1.business_day.ago }

          let(:params)             do
            {
              id: kase.id,
              ico: {
                date_ico_decision_received_yyyy: new_date_responded.year,
                date_ico_decision_received_mm: new_date_responded.month,
                date_ico_decision_received_dd: new_date_responded.day,
                ico_decision: "overturned",
              },
            }
          end

          before do
            sign_in manager
            patch :update_closure, params:
          end

          it "updates the cases date responded field" do
            kase.reload
            expect(kase.date_ico_decision_received).not_to eq new_date_responded
          end

          it "updates the cases refusal reason" do
            kase.reload
            expect(kase.ico_decision).not_to eq "upheld"
          end

          it "redirects to the case details page" do
            expect(response).to redirect_to case_path(id: kase.id)
          end
        end
      end
    end
  end

  describe "SAR" do
    describe "#edit" do
      let(:kase) { create :accepted_ico_sar_case }

      include_examples "edit case spec"
    end

    describe "closable" do
      describe "#closure_outcomes" do
        let(:kase) { create :responded_ico_sar_case }

        include_examples "closure outcomes spec", described_class
      end

      describe "#edit_closure" do
        let(:kase)    { create :closed_ico_sar_case }
        let(:manager) { find_or_create :disclosure_bmt_user }

        include_examples "edit closure spec", described_class
      end
    end
  end

  describe "#new_linked_cases_for" do
    let(:sar_case)      { create :sar_case }
    let(:sar_case2)     { create :sar_case }
    let(:foi_case)      { create :foi_case }
    let(:foi_case2)     { create :foi_case }
    let(:foi)           { find_or_create(:foi_correspondence_type) }

    let(:foi_only_team) do
      create :business_unit,
             correspondence_type_ids: [foi.id]
    end
    # Case managed by foi-only team.
    let(:foi_only_case) { create :foi_case, managing_team: foi_only_team }
    let(:foi_only_user) { create :manager, managing_teams: [foi_only_team] }
    let(:user)          { find_or_create :disclosure_bmt_user }

    let(:json_response) { JSON.parse(response.body) }

    def new_linked_cases_for_request(additional_params = {})
      get :new_linked_cases_for,
          xhr: true,
          format: :js,
          params: params.merge(additional_params)
    end

    context "when ico correspondences" do
      before do
        sign_in user
      end

      context "and linking original case" do
        let(:params) do
          {
            correspondence_type: "ico",
            link_type: "original",
          }
        end

        it "renders the partial on success" do
          new_linked_cases_for_request(original_case_number: foi_case.number)

          expect(response).to have_http_status :ok
          expect(response).to render_template("cases/ico/case_linking/_linked_cases")
          expect(assigns[:linked_cases]).to eq [foi_case]
        end

        it "returns an error if original_case_number is blank" do
          new_linked_cases_for_request(original_case_number: "")

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Enter original case number"
        end

        it "returns an error if original_case_number doesn't exist" do
          new_linked_cases_for_request(original_case_number: "n283nau")

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Original case not found"
        end

        it "doesn't allow linking of case that isn't an FOI or SAR or FOI internal review" do
          offender_sar = create(:offender_sar_case)
          new_linked_cases_for_request(original_case_number: offender_sar.number)

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Original case must be one of the [FOI, FOI - Internal review for timeliness, FOI - Internal review for compliance, SAR - Non-offender]."
        end

        context "when a user only allowed to view FOI cases" do
          let(:user) { foi_only_user }

          it "doesn't allow viewing original cases if not authorised" do
            new_linked_cases_for_request(original_case_number: sar_case.number)

            expect(response).to have_http_status :bad_request
            expect(json_response["linked_case_error"])
              .to eq "Not authorised to view case"
          end
        end
      end

      context "when linking related case" do
        let(:params) do
          {
            correspondence_type: "ico",
            link_type: "related",
          }
        end

        it "renders the partial on success" do
          new_linked_cases_for_request(
            original_case_number: foi_case.number,
            related_case_number: foi_case2.number,
            related_case_ids: nil,
          )

          expect(response).to have_http_status :ok
          expect(response).to render_template("cases/ico/case_linking/_linked_cases")
          expect(assigns[:linked_cases]).to eq [foi_case2]
        end

        it "returns an error if related_case_number is blank" do
          new_linked_cases_for_request(
            original_case_number: foi_case.number,
            related_case_number: "",
          )

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Enter related case number"
        end

        it "returns an error if related_case_number doesn't exist" do
          new_linked_cases_for_request(
            original_case_number: foi_case.number,
            related_case_number: "2nnahk",
          )

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Related case not found"
        end

        it "doesn't allow linking of SAR case to FOI ICO" do
          new_linked_cases_for_request(
            original_case_number: foi_case.number,
            related_case_number: sar_case.number,
            related_case_ids: nil,
          )

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "You've linked an FOI case as the original for this " \
                   "appeal. You can now only link other FOI cases or " \
                   "internal reviews as related to this cases."
        end

        it "doesn't allow re-linking of original case as also related case" do
          new_linked_cases_for_request(
            original_case_number: foi_case.number,
            related_case_number: foi_case.number,
            related_case_ids: nil,
          )

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Case is already linked"
        end

        it "doesn't allow re-linking of related case again" do
          new_linked_cases_for_request(
            original_case_number: foi_case.number,
            related_case_number: foi_case2.number,
            related_case_ids: foi_case2.id,
          )

          expect(response).to have_http_status :bad_request
          expect(json_response["linked_case_error"])
            .to eq "Case is already linked"
        end

        context "when a user only allowed to view FOI cases" do
          let(:user) { foi_only_user }

          it "doesn't allow viewing related cases if not authorised" do
            new_linked_cases_for_request(
              original_case_number: foi_case.number,
              related_case_number: sar_case.number,
              related_case_ids: nil,
            )

            expect(response).to have_http_status :bad_request
            expect(json_response["linked_case_error"])
              .to eq "Not authorised to view case"
          end

          it "removes any existing linked related cases if not authorised" do
            new_linked_cases_for_request(
              original_case_number: foi_case.number,
              related_case_number: foi_case2.number,
              related_case_ids: sar_case.number,
            )

            expect(response).to have_http_status :ok
            expect(response).to render_template("cases/ico/case_linking/_linked_cases")
            expect(assigns[:linked_cases]).not_to include(sar_case)
          end
        end
      end
    end
  end

  describe "#record_late_team" do
    before do
      sign_in approver
      allow_any_instance_of(Case::ICO::SAR).to receive(:responded_late?).and_return(true) # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Case::ICO::FOI).to receive(:responded_late?).and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    let(:approved_ico)        { create :approved_ico_foi_case, :flagged_accepted }
    let(:approved_sar_ico)    { create :approved_ico_sar_case }
    let(:approving_team)      { approved_ico.approving_teams.first }
    let(:approver)            { approving_team.users.first }

    it "authorizes" do
      expect {
        patch :record_late_team, params: { id: approved_ico.id }
      }.to require_permission(:can_respond?)
        .with_args(approver, approved_ico)
    end

    it "sets @case" do
      patch :record_late_team, params: { id: approved_ico.id }
      expect(assigns(:case)).to eq approved_ico
    end

    context "with foi" do
      it "redirects to case details page" do
        patch :record_late_team, params: {
          id: approved_ico.id,
          ico: {
            late_team_id: approving_team.id,
          },
        }

        expect(response).to redirect_to(case_path(approved_ico))
      end

      it "calls the state_machine method" do
        patch :record_late_team, params: {
          id: approved_ico.id,
          ico: {
            late_team_id: approving_team.id,
          },
        }

        stub_find_case(approved_ico.id) do |kase|
          expect(kase.state_machine).to have_received(:respond!)
            .with(acting_user: approver,
                  acting_team: approving_team)
        end
      end

      it "sets the late team" do
        patch :record_late_team, params: {
          id: approved_ico.id,
          ico: {
            late_team_id: approving_team.id,
          },
        }

        approved_ico.reload
        expect(approved_ico.late_team_id).to eq approving_team.id
      end

      context "without team" do
        it "renders late team page" do
          patch :record_late_team, params: {
            id: approved_ico.id,
          }

          expect(response).to render_template(:late_team)
        end
      end
    end

    context "with sar" do
      it "sets the late team" do
        patch :record_late_team, params: {
          id: approved_sar_ico.id,
          ico: {
            late_team_id: approving_team.id,
          },
        }

        approved_sar_ico.reload
        expect(approved_sar_ico.late_team_id).to eq approving_team.id
      end

      it "renders complaint outcome page" do
        patch :record_late_team, params: {
          id: approved_sar_ico.id,
          ico: {
            late_team_id: approving_team.id,
          },
        }

        expect(response).to render_template(:record_sar_complaint_outcome)
      end

      context "without team" do
        it "renders late team page" do
          patch :record_late_team, params: {
            id: approved_sar_ico.id,
          }

          expect(response).to render_template(:late_team)
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
