require "rails_helper"

RSpec.describe Cases::OffenderSARController, type: :controller do
  let(:responder) { find_or_create :branston_user }

  let(:params) do
    {
      correspondence_type: "offender_sar",
      offender_sar: {
        requester_type: "member_of_the_public",
        type: "Offender",
        name: "A. N. Other",
        postal_address: "102 Petty France",
        email: "member@public.com",
        subject: "Offender SAR request from controller spec",
        message: "Offender SAR about a former offender",
        received_date_dd: Time.zone.today.day.to_s,
        received_date_mm: Time.zone.today.month.to_s,
        received_date_yyyy: Time.zone.today.year.to_s,
        delivery_method: :sent_by_email,
        flag_for_disclosure_specialists: false,
      },
    }
  end

  describe "authentication" do
    include_examples "can_add_case policy spec", Case::SAR::Offender
  end

  # Not using shared_examples/new_spec due to the way Offender SAR Controller
  # sets `@case` to be a OffenderSARCaseForm rather than a decorator at present
  describe "#new" do
    let(:case_types) { %w[Case::SAR::Offender] }
    let(:params) { { correspondence_type: "offender_sar" } }

    before do
      sign_in responder
    end

    context "when the user is allowed to manage offender sar cases" do
      it "authorizes" do
        expect { get :new, params: }
          .to require_permission(:can_add_case?)
          .with_args(responder, Case::SAR::Offender)
      end
    end

    context "when the user is a manager for other types" do
      let(:manager) { find_or_create :disclosure_bmt_user }

      before do
        sign_in manager
      end

      it "redirects" do
        get(:new, params:)
        expect(flash[:alert]).to eq "You are not authorised to create new cases."
        expect(response)
          .to redirect_to(root_path)
      end
    end

    it "renders the new template with a form object" do
      get(:new, params:)
      expect(response).to render_template(:new)
      expect(assigns(:case)).to be_a OffenderSARCaseForm
      expect(assigns(:case_types)).to match_array %w[Case::SAR::Offender]
    end

    context "when starting a rejected offender sar case" do
      let(:params) do
        {
          rejected: true,
          correspondence_type: "offender_sar",
        }
      end

      it "renders the new template with is_rejected as true" do
        get(:new, params:)
        expect(response).to render_template(:new)
      end

      it "sets the current_state to 'invalid_submission'" do
        get(:new, params:)
        expect(assigns(:case).current_state).to eq("invalid_submission")
      end
    end
  end

  describe "#create" do
    before do
      sign_in responder
      post(:create, params:)
    end

    it "assigns a sar_offender case" do
      expect(assigns(:case)).to be_a Case::SAR::Offender
    end

    it "doesn't set a flash message" do
      expect(flash[:notice]).to eq nil
    end

    describe "partial validations" do
      let(:errors) { assigns(:case).errors.messages }
      let(:third_party_base_params) do
        {
          third_party_relationship: "",
          third_party_name: "",
          third_party_company_name: "",
          postal_address: "",
        }
      end

      context "with step subject-details" do
        let(:params) do
          {
            current_step: "subject-details",
            offender_sar: {
              subject_full_name: "",
              subject_address: "",
            },
          }
        end

        it "validates subject name and address" do
          remains_on_step "subject-details"
          expect(errors[:subject_full_name]).to eq ["cannot be blank"]
          expect(errors[:subject_address]).to eq ["cannot be blank"]
        end

        # unset radio options and date fields are hard to validate
        # so offender_sar_case_form#params_for_step
        # contains logic to set required ones if missing
        it "sets empty values and validates other fields" do
          remains_on_step "subject-details"
          expect(errors[:date_of_birth]).to eq ["cannot be blank"]
          expect(errors[:subject_type]).to eq ["cannot be blank"]
          expect(errors[:flag_as_high_profile]).to eq ["cannot be blank"]
        end
      end

      context "with step requester-details" do
        context "when third party absent" do
          let(:params) do
            {
              current_step: "requester-details",
              offender_sar: third_party_base_params,
            }
          end

          it "requires third_party to be set" do
            remains_on_step "requester-details"
            expect(errors[:third_party]).to eq ["cannot be blank"]
          end
        end

        context "when third party true" do
          let(:params) do
            {
              current_step: "requester-details",
              offender_sar: third_party_base_params.merge(third_party: true),
            }
          end

          it "validates requester details" do
            remains_on_step "requester-details"
            third_party_validations_found(errors)
          end
        end

        context "when third party false" do
          let(:params) do
            {
              current_step: "requester-details",
              offender_sar: third_party_base_params.merge(third_party: false),
            }
          end

          it "redirects to the next step" do
            expect(response).to be_redirect
          end
        end
      end

      describe "rejected offender sar" do
        context "with step reason-rejected" do
          context "when reason absent" do
            let(:params) do
              {
                current_step: "reason-rejected",
                offender_sar: {
                  rejected_reasons: [""],
                },
              }
            end

            it "requires a reason-rejected option to be set" do
              remains_on_step "reason-rejected"
              expect(errors[:rejected_reasons]).to eq ["Reason for rejecting the case cannot be blank"]
            end
          end

          context "when other option is chosen but no reason given" do
            let(:params) do
              {
                current_step: "reason-rejected",
                offender_sar: {
                  rejected_reasons: %w[other],
                  other_rejected_reason: "",
                },
              }
            end

            it "requires an other reason-rejected option to be given" do
              remains_on_step "reason-rejected"
              expect(errors[:other_rejected_reason]).to eq ["Other reason for rejecting the case cannot be blank"]
            end
          end
        end
      end

      context "with step recipient-details" do
        context "when recipient absent" do
          let(:params) do
            {
              current_step: "recipient-details",
              offender_sar: third_party_base_params,
            }
          end

          it "requires recipient to be set" do
            remains_on_step "recipient-details"
            expect(errors[:recipient]).to eq ["cannot be blank"]
          end
        end

        context "when recipient is third party" do
          let(:params) do
            {
              current_step: "recipient-details",
              offender_sar: third_party_base_params.merge(recipient: "third_party_recipient"),
            }
          end

          it "validates recipient details" do
            remains_on_step "recipient-details"
            third_party_validations_found(errors)
          end
        end
      end

      context "with step request-details" do
        context "when request dated in future" do
          let(:future_date) { 1.day.from_now }
          let(:params) do
            {
              current_step: "request-details",
              offender_sar: {
                request_dated_dd: future_date.day,
                request_dated_mm: future_date.month,
                request_dated_yyyy: future_date.year,
              },
            }
          end

          it "fails to be valid" do
            remains_on_step "request-details"
            expect(errors[:request_dated]).to eq ["cannot be in the future."]
          end
        end
      end

      context "with step date-received" do
        context "when date missing" do
          let(:params) do
            {
              current_step: "date-received",
              offender_sar: { dummy_field: true },
            }
          end

          it "requires received date to be set" do
            remains_on_step "date-received"
            expect(errors[:received_date]).to eq ["cannot be blank"]
          end
        end

        context "when date received in future" do
          let(:future_date) { 1.day.from_now }
          let(:params) do
            {
              current_step: "date-received",
              offender_sar: {
                received_date_dd: future_date.day,
                received_date_mm: future_date.month,
                received_date_yyyy: future_date.year,
              },
            }
          end

          it "fails to be valid" do
            remains_on_step "date-received"
            expect(errors[:received_date]).to eq ["cannot be in the future."]
          end
        end
      end
    end
  end

  describe "transitions" do
    {
      data_to_be_requested: :mark_as_waiting_for_data,
      waiting_for_data: :mark_as_ready_for_vetting,
      ready_for_vetting: :mark_as_vetting_in_progress,
      vetting_in_progress: :mark_as_ready_to_copy,
      ready_to_copy: :mark_as_ready_to_dispatch,
      ready_to_dispatch: :close,
    }.each do |state, transition_event|
      context "with Offender SAR in #{state} state" do
        it_behaves_like "edit offender sar spec", state.to_sym, transition_event
      end
    end
  end

  describe "#edit" do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) { { id: offender_sar_case.id } }

    before do
      sign_in responder
    end

    it "assigns and displays" do
      get(:edit, params:)
      expect(response).to render_template(:edit)
      expect(assigns(:case)).to be_a Case::SAR::Offender
    end
  end

  describe "#update" do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) do
      {
        id: offender_sar_case.id,
        offender_sar: {
          requester_type: "member_of_the_public",
          type: "Offender",
          name: "A. N. Other",
          postal_address: "102 Petty France",
          email: "member@public.com",
          subject: "Offender SAR request from controller spec",
          message: "Offender SAR about a former offender",
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
          delivery_method: :sent_by_email,
          flag_for_disclosure_specialists: false,
        },
      }
    end

    let(:same_params) do
      {
        id: offender_sar_case.id,
        offender_sar: {
          name: offender_sar_case.name,
          postal_address: offender_sar_case.postal_address,
          subject: offender_sar_case.subject,
          message: offender_sar_case.message,
        },
      }
    end

    before do
      sign_in responder
    end

    context "without change anything" do
      it "check the flash" do
        patch :update, params: same_params
        expect(assigns(:case)).to be_a Case::SAR::Offender
        expect(flash[:notice]).to eq nil
        expect(flash[:alert]).to eq "No changes were made"
        expect(offender_sar_case.object.transitions.where(event: "edit_case").count).to eq 0
      end
    end

    context "with valid params" do
      before do
        patch(:update, params:)
      end

      it "assigns a sar_offender case" do
        expect(assigns(:case)).to be_a Case::SAR::Offender
      end

      it "sets the flash" do
        expect(offender_sar_case.object.transitions.where(event: "edit_case").count).to be >= 1
        expect(flash[:notice]).to eq "Case updated"
      end

      it "redirects to the new case assignment page" do
        expect(response)
          .to redirect_to(case_path(offender_sar_case))
      end
    end
  end

  describe "#confirm_sent_to_sscl" do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }
    let(:params) do
      {
        id: offender_sar_case.id,
        offender_sar: {
          sent_to_sscl_at_dd: "10",
          sent_to_sscl_at_mm: "01",
          sent_to_sscl_at_yyyy: "2023",
        },
      }
    end
    let(:service) { instance_double(CaseUpdateSentToSsclService, call: nil, result: :ok, message: nil) }

    before do
      sign_in responder
      allow(CaseUpdateSentToSsclService).to receive(:new).and_return(service)
    end

    context "with valid params" do
      before do
        patch(:confirm_sent_to_sscl, params:)
      end

      it "assigns a sar_offender case" do
        expect(assigns(:case)).to be_a Case::SAR::Offender
      end

      it "sets the flash" do
        expect(flash[:notice]).to eq "Case updated"
      end

      it "redirects to the new case assignment page" do
        expect(response).to redirect_to(case_path(offender_sar_case))
      end
    end
  end

  describe "#accepted_date_received" do
    let(:rejected_offender_sar_case) { create(:offender_sar_case, :rejected).decorate }
    let(:params) { { id: rejected_offender_sar_case.id } }

    before do
      sign_in responder
    end

    it "renders the accepted date received page" do
      get(:accepted_date_received, params:)
      expect(response).to render_template(:accepted_date_received)
    end

    it "sets received_date to nil" do
      get(:accepted_date_received, params:)
      expect(assigns(:case).received_date_dd).to eq ""
      expect(assigns(:case).received_date_mm).to eq ""
      expect(assigns(:case).received_date_yyyy).to eq ""
    end
  end

  describe "#confirm_accepted_date_received" do
    let(:rejected_offender_sar_case) { create :offender_sar_case, :rejected }
    let(:params) do
      {
        id: rejected_offender_sar_case.id,
        offender_sar: {
          received_date_dd: Time.zone.today.day.to_s,
          received_date_mm: Time.zone.today.month.to_s,
          received_date_yyyy: Time.zone.today.year.to_s,
        },
      }
    end

    before do
      sign_in responder
    end

    context "with valid params" do
      let(:new_date_params) do
        {
          id: rejected_offender_sar_case.id,
          offender_sar: {
            received_date_dd: "01",
            received_date_mm: "02",
            received_date_yyyy: "2023",
          },
        }
      end

      before do
        patch(:confirm_accepted_date_received, params: new_date_params)
      end

      it "sets the flash" do
        expect(flash[:notice]).to eq "Case updated"
      end

      it "redirects to the case details page" do
        expect(response).to redirect_to(case_path(rejected_offender_sar_case))
      end

      it "changes the current_state to 'data to be requested'" do
        expect(assigns(:case).current_state).to eq "data_to_be_requested"
      end
    end
  end

  # Utility methods

  def third_party_validations_found(errors)
    expect(errors[:third_party_name]).to eq ["cannot be blank if company name not given"]
    expect(errors[:third_party_company_name]).to eq ["cannot be blank if representative name not given"]
    expect(errors[:third_party_relationship]).to eq ["cannot be blank"]
    expect(errors[:postal_address]).to eq ["cannot be blank"]
  end

  def remains_on_step(step)
    expect(response).to be_successful
    expect(assigns(:case).current_step).to eq step
  end
end
