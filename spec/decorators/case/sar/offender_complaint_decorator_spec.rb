require "rails_helper"

describe Case::SAR::OffenderComplaintDecorator do
  let(:offender_sar_complaint) { build_stubbed(:offender_sar_complaint, date_responded: Date.new(2020, 1, 10), received_date: Date.new(2020, 1, 1)).decorate }
  let(:accepted_complaint_case) { :high_priority }

  it "instantiates the correct decorator" do
    expect(Case::SAR::OffenderComplaint.new.decorate).to be_instance_of described_class
  end

  describe "#current_step" do
    it "returns the first step by default" do
      expect(offender_sar_complaint.current_step).to eq "link-offender-sar-case"
    end
  end

  describe "#next_step" do
    it "causes #current_step to return the next step" do
      offender_sar_complaint.next_step

      expect(offender_sar_complaint.current_step).to eq "confirm-offender-sar"
    end
  end

  describe "#get_step_partial" do
    it "returns the first step as default filename" do
      expect(offender_sar_complaint.get_step_partial).to eq "link_offender_sar_case_step"
    end

    it "returns each subsequent step as a partial filename" do
      expect(offender_sar_complaint.get_step_partial).to eq "link_offender_sar_case_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "confirm_offender_sar_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "complaint_type_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "requester_details_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "recipient_details_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "requested_info_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "request_details_step"
      offender_sar_complaint.next_step
      expect(offender_sar_complaint.get_step_partial).to eq "date_received_step"
    end
  end

  describe "#time_taken" do
    it "returns total number of days between date received and date responded" do
      expect(offender_sar_complaint.time_taken).to eq "9 calendar days"
    end
  end

  describe "#complaint_type" do
    context "when standard complaint" do
      it "returns Standard" do
        expect(offender_sar_complaint.complaint_type).to eq "Standard"
      end
    end

    context "when ICO complaint" do
      let(:offender_sar_complaint) { build_stubbed(:offender_sar_complaint, complaint_type: "ico_complaint", date_responded: Date.new(2020, 1, 10), received_date: Date.new(2020, 1, 1)).decorate }

      it "returns ICO" do
        expect(offender_sar_complaint.complaint_type).to eq "ICO"
      end
    end

    context "when litigation complaint" do
      let(:offender_sar_complaint) { build_stubbed(:offender_sar_complaint, complaint_type: "litigation", date_responded: Date.new(2020, 1, 10), received_date: Date.new(2020, 1, 1)).decorate }

      it "returns Litigation" do
        expect(offender_sar_complaint.complaint_type).to eq "Litigation"
      end
    end
  end

  describe "#type_printer" do
    it "pretty prints Case - Standard" do
      expect(offender_sar_complaint.pretty_type).to eq "Complaint - Standard"
    end

    it "pretty prints Case - ICO" do
      offender_sar_complaint.complaint_type = "ico_complaint"
      expect(offender_sar_complaint.pretty_type).to eq "Complaint - ICO"
    end

    it "pretty prints Case - Litigation" do
      offender_sar_complaint.complaint_type = "litigation_complaint"
      expect(offender_sar_complaint.pretty_type).to eq "Complaint - Litigation"
    end
  end

  describe "#highlight_flag" do
    context "when Offender SAR Complaint - high priority" do
      it 'returns string of "High priority"' do
        priority_case = create(:accepted_complaint_case, :high_priority, :flagged).decorate
        expect(priority_case.highlight_flag).to eq '<div class="offender_sar_complaint-priority_flag">' \
          '<span class="visually-hidden">This is a </span>High priority<span class="visually-hidden"> case</span></div>'
      end
    end

    context "when Offender SAR Complaint - normal priority" do
      it "returns blank string when priority is normal" do
        priority_case = create(:accepted_complaint_case, :flagged).decorate
        expect(priority_case.highlight_flag).to eq ""
      end
    end
  end
end
