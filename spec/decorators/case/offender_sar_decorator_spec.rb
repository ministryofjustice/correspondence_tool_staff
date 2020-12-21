require "rails_helper"

describe Case::SAR::OffenderDecorator do
  let(:offender_sar_case) {build_stubbed(:offender_sar_case, date_responded: Date.new(2020,1,10), received_date: Date.new(2020,1,1)).decorate}

  it 'instantiates the correct decorator' do
    expect(Case::SAR::Offender.new.decorate).to be_instance_of Case::SAR::OffenderDecorator
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

  describe "#time_taken" do
    it "returns total number of days between date received and date responded" do
      expect(offender_sar_case.time_taken).to eq "9 calendar days"
    end
  end

  describe '#type_printer' do
    it 'pretty prints Case' do
      expect(offender_sar_case.pretty_type).to eq 'Offender SAR'
    end
  end

end
