require "rails_helper"

module Builders
  describe SteppedCaseBuilder do
    let(:user) { find_or_create(:sar_responder) }
    let(:sar_case) { create(:sar_case) }
    let(:case_type) { Case::SAR::InternalReview }
    let(:step) { "link-sar-case" }
    let(:last_step) { "case-details" }
    let(:received_data) { Date.current }

    let(:params) do
      params = ActionController::Parameters.new(
        {
          email: "asd@casd.com",
          message: "Some case details",
          name: "Tom Jones",
          postal_address: "",
          received_date_dd: received_data.day.to_s,
          received_date_mm: received_data.month.to_s,
          received_date_yyyy: received_data.year.to_s,
          sar_ir_subtype: "timeliness",
          subject: "IR of 211208003 - This is a case",
          subject_type: "offender",
          third_party: "true",
          third_party_relationship: "Solicitor",
          reply_method: "send_by_email",
        },
      )
      params.permit!
    end

    let(:invalid_params) do
      params = ActionController::Parameters.new(
        {
          delivery_method: nil,
          email: "test@test.com",
          name: "Tom Jones",
          postal_address: "",
          requester_type: nil,
          message: "",
          subject: "Thing",
          subject_type: "offender",
          third_party: true,
          third_party_relationship: "Barrister",
          reply_method: "send_by_email",
        },
      )
      params.permit!
    end

    let(:session) do
      ActiveSupport::HashWithIndifferentAccess.new(
        {
          sar_internal_review_state: {
            flag_for_disclosure_specialists: "yes",
            original_case_number: sar_case.number.to_s,
            original_case_id: sar_case.id,
            delivery_method: nil,
            email: "test@test.com",
            name: "Tom Jones",
            postal_address: "",
            requester_type: nil,
            subject: "Thing",
            subject_full_name: "Dave Smith",
            subject_type: "offender",
            third_party: true,
            third_party_relationship: "Barrister",
            reply_method: "send_by_email",
          },
        },
      )
    end

    let(:builder_without_params) do
      described_class.new(
        case_type:,
        session:,
        step:,
        creator: user,
      )
    end

    let(:builder_not_on_last_step) do
      described_class.new(
        case_type:,
        session:,
        step:,
        creator: user,
        params:,
      )
    end

    let(:invalid_builder_on_last_step) do
      described_class.new(
        case_type:,
        session:,
        step: last_step,
        creator: user,
        params: invalid_params,
      )
    end

    let(:valid_builder_on_last_step) do
      described_class.new(
        case_type:,
        session:,
        step: last_step,
        creator: user,
        params:,
      )
    end

    context "when building for #new" do
      before do
        builder_without_params.build
      end

      it "can build a stepped case from a session" do
        expect(builder_without_params.kase).to be_a(case_type)
      end

      it "can set the creator and the step of the case" do
        expect(builder_without_params.kase.creator).to match(user)
      end

      it "can set the current step" do
        expect(builder_without_params.kase.current_step).to match(step)
      end

      it "is not ready for creation" do
        expect(builder_without_params.kase_ready_for_creation?).to be(false)
      end
    end

    context "when building for #create" do
      context "and case is valid and steps are complete" do
        it "is ready for creation" do
          valid_builder_on_last_step.build

          expect(valid_builder_on_last_step.kase).to be_valid
          expect(valid_builder_on_last_step.kase.current_step).to match(last_step)
          expect(valid_builder_on_last_step.kase_ready_for_creation?).to be(true)
        end
      end

      context "and case is invalid and steps are complete" do
        it "is not ready for creation" do
          invalid_builder_on_last_step.build
          expect(invalid_builder_on_last_step.kase).not_to be_valid
          expect(invalid_builder_on_last_step.kase.current_step).to match(last_step)
          expect(invalid_builder_on_last_step.kase_ready_for_creation?).to be(false)
        end
      end

      context "and steps are incomplete" do
        it "is not ready for creation" do
          builder_not_on_last_step.build
          expect(builder_not_on_last_step.kase).not_to be_valid
          expect(builder_not_on_last_step.kase.current_step).to match(step)
          expect(builder_not_on_last_step.kase_ready_for_creation?).to be(false)
        end
      end
    end
  end
end
