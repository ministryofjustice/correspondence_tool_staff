require "rails_helper"

describe Case::ICO::BaseDecorator do
  let(:closed_ico_foi_case) { (create :closed_ico_foi_case).decorate }
  let(:closed_overturned_foi_case) do
    (create :closed_ico_foi_case,
            :overturned_by_ico).decorate
  end
  let(:closed_overturned_sar_case) do
    (create :closed_ico_sar_case,
            :overturned_by_ico).decorate
  end

  it "instantiates the correct decorator" do
    expect(Case::ICO::Base.new.decorate).to be_instance_of described_class
  end

  describe "#formatted_date_ico_decision_received" do
    it "returns a formated date" do
      closed_ico_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.formatted_date_ico_decision_received).to eq "13 Aug 2017"
    end
  end

  describe "#pretty_ico_decision" do
    it "returns upheld description" do
      closed_ico_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.pretty_ico_decision)
          .to eq "Upheld by ICO"
    end

    it "returns overturned description" do
      closed_overturned_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_overturned_foi_case.pretty_ico_decision)
          .to eq "Overturned by ICO"
    end

    it "returns sar_complaint_outcome when it exists" do
      closed_overturned_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      closed_overturned_sar_case.sar_complaint_outcome = "bau_ico_informed"
      expect(closed_overturned_sar_case.pretty_ico_decision)
          .to eq "Overturned by ICO<div>Was originally treated as BAU, the ICO have been informed</div>"
    end

    it "returns other sar_complaint_outcome when it exists" do
      closed_overturned_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      closed_overturned_sar_case.sar_complaint_outcome = "other_outcome"
      closed_overturned_sar_case.other_sar_complaint_outcome_note = "some other reason"
      expect(closed_overturned_sar_case.pretty_ico_decision)
          .to eq "Overturned by ICO<div>some other reason</div>"
    end
  end

  describe "#original_internal_deadline" do
    it "returns a formatted date" do
      closed_ico_foi_case.object.original_internal_deadline = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.original_internal_deadline).to eq "13 Aug 2017"
    end
  end

  describe "#original_external_deadline" do
    it "returns a formatted date" do
      closed_ico_foi_case.object.original_external_deadline = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.original_external_deadline).to eq "13 Aug 2017"
    end
  end

  describe "#original_date_responded" do
    it "returns a formatted date" do
      closed_ico_foi_case.object.original_date_responded = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.original_date_responded).to eq "13 Aug 2017"
    end
  end
end
