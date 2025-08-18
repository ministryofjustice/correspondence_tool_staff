require "rails_helper"

RSpec.describe Cases::OffenderSARComplaintController, type: :controller do
  let(:responder) { find_or_create :branston_user }

  describe "authentication" do
    let(:params) do
      {
        correspondence_type: "offender_sar_complaint",
        offender_sar_complaint: {
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

    include_examples "can_add_case policy spec", Case::SAR::OffenderComplaint
  end

  # Not using shared_examples/new_spec due to the way Offender SAR Controller
  # sets `@case` to be a OffenderSARCaseForm rather than a decorator at present
  describe "#new" do
    let(:case_types) { %w[Case::SAR::OffenderComplaint] }
    let(:params) { { correspondence_type: "offender_sar_complaint" } }

    before do
      sign_in responder
    end

    context "when the user is allowed to manage offender sar cases" do
      it "authorizes" do
        expect { get :new, params: }
          .to require_permission(:can_add_case?)
          .with_args(responder, Case::SAR::OffenderComplaint)
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
      expect(assigns(:case_types)).to match_array %w[Case::SAR::OffenderComplaint]
    end
  end

  describe "#create" do
    describe "partial validations" do
      let(:errors) { assigns(:case).errors.messages }
      let(:complaint) { create(:offender_sar_complaint) }
      let(:foi) { create(:closed_case) }
      let(:offender_sar_base_params) do
        {
          third_party_relationship: "",
          third_party_name: "",
          third_party_company_name: "",
          postal_address: "",
        }
      end

      before do
        sign_in responder
        post(:create, params:)
        expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint # rubocop:disable RSpec/ExpectInHook
        expect(flash[:notice]).to eq nil # rubocop:disable RSpec/ExpectInHook
      end

      context "with step link-offender-sar-case" do
        context "when original sar case number absent" do
          let(:params) do
            {
              current_step: "link-offender-sar-case",
              offender_sar_complaint: offender_sar_base_params,
            }
          end

          it "requires original case number to be set" do
            remains_on_step "link-offender-sar-case"
            expect(errors[:original_case_number]).to eq ["can't be blank"]
          end
        end

        context "when the original case is case out of permission e.g. FOI" do
          let(:params) do
            {
              current_step: "link-offender-sar-case",
              offender_sar_complaint: offender_sar_base_params.merge(original_case_number: foi.number),
            }
          end

          it "The user needs to be allowed to view the original case" do
            remains_on_step "link-offender-sar-case"
            expect(errors[:original_case_number]).to eq ["cannot be authorised to link this case"]
          end
        end

        context "when the original case is wrong type " do
          let(:params) do
            {
              current_step: "link-offender-sar-case",
              offender_sar_complaint: offender_sar_base_params.merge(original_case_number: complaint.number),
            }
          end

          it "requires the original case is the type allowed for complaint case" do
            remains_on_step "link-offender-sar-case"
            expect(errors[:original_case]).to eq ["Original case must be Offender SAR"]
          end
        end
      end

      context "with step complaint-type" do
        let(:params) do
          {
            current_step: "complaint-type",
            offender_sar_complaint: offender_sar_base_params,
          }
        end

        context "when complaint-type absent" do
          context "when complaint-type absent" do
            it "requires complaint-type to be set" do
              remains_on_step "complaint-type"
              expect(errors[:complaint_type]).to eq ["cannot be blank"]
            end
          end

          context "when complaint-type present" do
            context "when ico" do
              let(:params) do
                {
                  current_step: "complaint-type",
                  offender_sar_complaint: offender_sar_base_params.merge(complaint_type: "ico_complaint"),
                }
              end

              it "requires ico contact name" do
                expect(errors[:ico_contact_name]).to eq ["cannot be blank"]
              end

              it "requires ico contact phone or email" do
                expect(errors[:ico_contact_email]).to eq ["cannot be blank if ICO contact phone not given"]
                expect(errors[:ico_contact_phone]).to eq ["cannot be blank if ICO contact email not given"]
              end

              it "requires ico reference" do
                expect(errors[:ico_reference]).to eq ["cannot be blank"]
              end
            end

            context "when litigation" do
              let(:params) do
                {
                  current_step: "complaint-type",
                  offender_sar_complaint: offender_sar_base_params.merge(complaint_type: "litigation_complaint"),
                }
              end

              it "requires gld contact name" do
                expect(errors[:gld_contact_name]).to eq ["cannot be blank"]
              end

              it "requires gld contact phone or email" do
                expect(errors[:gld_contact_email]).to eq ["cannot be blank if GLD contact phone not given"]
                expect(errors[:gld_contact_phone]).to eq ["cannot be blank if GLD contact email not given"]
              end

              it "requires gld reference" do
                expect(errors[:gld_reference]).to eq ["cannot be blank"]
              end
            end
          end
        end

        context "when complaint-subtype absent" do
          it "requires complaint-subtype to be set" do
            remains_on_step "complaint-type"
            expect(errors[:complaint_subtype]).to eq ["cannot be blank"]
          end
        end

        context "when priority absent" do
          it "requires priority to be set" do
            remains_on_step "complaint-type"
            expect(errors[:priority]).to eq ["cannot be blank"]
          end
        end
      end

      context "with step requester-details" do
        context "when third party absent" do
          let(:params) do
            {
              current_step: "requester-details",
              offender_sar_complaint: offender_sar_base_params,
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
              offender_sar_complaint: offender_sar_base_params.merge(third_party: true),
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
              offender_sar_complaint: offender_sar_base_params.merge(third_party: false),
            }
          end

          it "redirects to the next step" do
            expect(response).to be_redirect
          end
        end
      end

      context "with step recipient-details" do
        context "when recipient absent" do
          let(:params) do
            {
              current_step: "recipient-details",
              offender_sar_complaint: offender_sar_base_params,
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
              offender_sar_complaint: offender_sar_base_params.merge(recipient: "third_party_recipient"),
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
              offender_sar_complaint: {
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
              offender_sar_complaint: { dummy_field: true },
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
              offender_sar_complaint: {
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

    context "when created by sscl user" do
      let(:original_case) { find_or_create :offender_sar_case }
      let(:sscl_user) { create :sscl_user }
      let(:future_date) { 1.day.from_now }
      let(:deadline_date) { 1.month.from_now }
      let(:params) do
        {
          current_step: "set-deadline",
          offender_sar_complaint: {
            external_deadline_dd: deadline_date.day,
            external_deadline_mm: deadline_date.month,
            external_deadline_yyyy: deadline_date.year,
          },
        }
      end

      let(:session) do
        {
          offender_sar_complaint_state: {
            received_date_dd: "1",
            received_date_mm: "1",
            received_date_yyyy: "2022",
            third_party: false,
            flag_as_high_profile: false,
            flag_as_dps_missing_data: true,
            date_of_birth_dd: "1",
            date_of_birth_mm: "1",
            date_of_birth_yyyy: "1990",
            subject_address: "subject address",
            subject_full_name: "full name",
            subject_type: "detainee",
            recipient: "subject_recipient",
            original_case:,
            complaint_type: "standard_complaint",
            complaint_subtype: "sscl_partial_case",
            priority: "normal",
            external_deadline_dd: deadline_date.day.to_s,
            external_deadline_mm: deadline_date.month.to_s,
            external_deadline_yyyy: deadline_date.year.to_s,
          },
        }
      end

      it "creates case and redirects" do
        sign_in sscl_user
        post(:create, params:, session:)
        expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint
        expect(flash[:notice]).to eq "Case created successfully"
        expect(response).to be_redirect
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
    let(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }
    let(:params) { { id: offender_sar_complaint.id } }

    before do
      sign_in responder
    end

    it "assigns and displays" do
      get(:edit, params:)
      expect(response).to render_template(:edit)
      expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint
    end
  end

  describe "#update" do
    let(:errors) { assigns(:case).errors.messages }

    let(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }
    let(:params) do
      {
        id: offender_sar_complaint.id,
        offender_sar_complaint: {
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
        id: offender_sar_complaint.id,
        offender_sar_complaint: {
          name: offender_sar_complaint.name,
          postal_address: offender_sar_complaint.postal_address,
          subject: offender_sar_complaint.subject,
          message: offender_sar_complaint.message,
        },
      }
    end

    let(:litigation_complaint) { create(:offender_sar_complaint, complaint_type: "litigation_complaint").decorate }
    let(:invalid_litigation_params) do
      {
        id: litigation_complaint.id,
        offender_sar_complaint: {
          gld_contact_name: "",
          gld_contact_email: "",
          gld_contact_phone: "",
          gld_reference: "",
        },
      }
    end

    let(:ico_complaint) { create(:offender_sar_complaint, complaint_type: "ico_complaint").decorate }
    let(:invalid_ico_params) do
      {
        id: ico_complaint.id,
        offender_sar_complaint: {
          ico_contact_name: "",
          ico_contact_email: "",
          ico_contact_phone: "",
          ico_reference: "",
        },
      }
    end

    before do
      sign_in responder
    end

    context "without change anything" do
      it "check the flash" do
        patch :update, params: same_params
        expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint
        expect(flash[:notice]).to eq nil
        expect(flash[:alert]).to eq "No changes were made"
        expect(offender_sar_complaint.object.transitions.where(event: "edit_case").count).to eq 0
      end
    end

    context "with invalid params for litigation complaint" do
      it "check the errors" do
        patch :update, params: invalid_litigation_params
        expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint
        expect(errors[:gld_contact_name]).to eq ["cannot be blank"]
        expect(errors[:gld_contact_email]).to eq ["cannot be blank if GLD contact phone not given"]
        expect(errors[:gld_contact_phone]).to eq ["cannot be blank if GLD contact email not given"]
        expect(errors[:gld_reference]).to eq ["cannot be blank"]
        expect(litigation_complaint.object.transitions.where(event: "edit_case").count).to eq 0
      end
    end

    context "with invalid params for ico complaint" do
      it "check the errors" do
        patch :update, params: invalid_ico_params
        expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint
        expect(errors[:ico_contact_name]).to eq ["cannot be blank"]
        expect(errors[:ico_contact_email]).to eq ["cannot be blank if ICO contact phone not given"]
        expect(errors[:ico_contact_phone]).to eq ["cannot be blank if ICO contact email not given"]
        expect(errors[:ico_reference]).to eq ["cannot be blank"]
        expect(ico_complaint.object.transitions.where(event: "edit_case").count).to eq 0
      end
    end

    context "with valid params" do
      before do
        patch(:update, params:)
      end

      it "assigns case as a sar offender complaint" do
        expect(assigns(:case)).to be_a Case::SAR::OffenderComplaint
      end

      it "sets the flash" do
        expect(offender_sar_complaint.object.transitions.where(event: "edit_case").count).to be >= 1
        expect(flash[:notice]).to eq "Case updated"
      end

      it "redirects to the new case assignment page" do
        expect(response)
          .to redirect_to(case_path(offender_sar_complaint))
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
