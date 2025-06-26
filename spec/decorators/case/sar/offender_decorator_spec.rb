require "rails_helper"

describe Case::SAR::OffenderDecorator do
  let(:offender_sar_case) do
    build(
      :offender_sar_case,
      date_responded: Date.new(2020, 1, 10),
      received_date: Date.new(2020, 1, 1),
    ).decorate
  end

  let(:rejected_offender_sar_case) { create(:offender_sar_case, :rejected).decorate }

  it "instantiates the correct decorator" do
    expect(Case::SAR::Offender.new.decorate).to be_instance_of described_class
  end

  describe "#current_step" do
    it "returns the first step by default" do
      expect(offender_sar_case.current_step).to eq "subject-details"
    end
  end

  describe "#next_step" do
    it "causes #current_step to return the next step" do
      offender_sar_case.next_step

      expect(offender_sar_case.current_step).to eq "requester-details"
    end
  end

  describe "#get_step_partial" do
    it "returns the first step as default filename" do
      expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
    end

    context "when a valid offender sar" do
      it "returns each subsequent step as a partial filename" do
        expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "requester_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "recipient_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "requested_info_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "request_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "date_received_step"
      end
    end

    context "when a rejected offender sar" do
      let(:offender_sar_case) do
        build_stubbed(
          :offender_sar_case, :rejected,
          date_responded: Date.new(2020, 1, 10),
          received_date: Date.new(2020, 1, 1)
        ).decorate
      end

      it "returns each subsequent step as a partial filename" do
        expect(offender_sar_case.get_step_partial).to eq "subject_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "requester_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "reason_rejected_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "recipient_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "requested_info_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "request_details_step"
        offender_sar_case.next_step
        expect(offender_sar_case.get_step_partial).to eq "date_received_step"
      end
    end
  end

  describe "#rejected_reasons_descriptions" do
    let(:offender_sar_case) do
      build_stubbed(
        :offender_sar_case, :rejected
      ).decorate
    end

    it "returns the REJECTED_REASONS hash value" do
      expect(offender_sar_case.rejected_reasons_descriptions).to eq "Further identification<br>Court data request"
    end

    context "when other_rejected_reason has a value" do
      let(:offender_sar_case) do
        build_stubbed(
          :offender_sar_case, :rejected, rejected_reasons: %w[other], other_rejected_reason: "Other reason"
        ).decorate
      end

      it "returns the REJECTED_REASONS hash value" do
        expect(offender_sar_case.rejected_reasons_descriptions).to eq "Other: Other reason"
      end
    end
  end

  describe "#time_taken" do
    it "returns total number of days between date received and date responded" do
      expect(offender_sar_case.time_taken).to eq "9 calendar days"
    end
  end

  describe "#type_printer" do
    it "pretty prints Case" do
      expect(offender_sar_case.pretty_type).to eq "Offender SAR"
    end

    context "when rejected" do
      it "pretty prints Case" do
        expect(rejected_offender_sar_case.pretty_type).to eq "Rejected Offender SAR"
      end
    end
  end

  describe "#request_methods_sorted" do
    it "returns an ordered request methods list of options" do
      expect(offender_sar_case.request_methods_sorted).to eq %w[email ico_web_portal post unknown verbal_request web_portal]
    end
  end

  describe "#request_method_for_display" do
    it 'does not return the "unknown" request method' do
      expect(offender_sar_case.request_methods_for_display).to match_array %w[email ico_web_portal post verbal_request web_portal]
    end

    it "returns an ordered request methods list of options for display" do
      expect(offender_sar_case.request_methods_for_display).to eq %w[email ico_web_portal post verbal_request web_portal]
    end
  end

  describe "#highlight_flag" do
    it "returns string of 'High profile' in a badge" do
      high_profile_case = create(:offender_sar_case, flag_as_high_profile: true).decorate
      expect(high_profile_case.highlight_flag).to eq '<div class="offender_sar-profile_flag">' \
        '<span class="visually-hidden">This is a </span>High profile<span class="visually-hidden"> case</span></div>'
    end

    it "returns string of ''" do
      high_profile_case = create(:offender_sar_case, flag_as_high_profile: false).decorate
      expect(high_profile_case.highlight_flag).to eq ""
    end
  end

  describe "#dps_missing_data_flag" do
    it "returns true if flag set to yes" do
      dps_missing_data_case = create(:offender_sar_case, flag_as_dps_missing_data: true).decorate
      expect(dps_missing_data_case.flag_as_dps_missing_data).to eq true
    end

    it "returns false if flag set to no" do
      dps_missing_data_case = create(:offender_sar_case, flag_as_dps_missing_data: false).decorate
      expect(dps_missing_data_case.flag_as_dps_missing_data).to eq false
    end
  end
end
