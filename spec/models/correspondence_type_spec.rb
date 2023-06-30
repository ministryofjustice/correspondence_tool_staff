# == Schema Information
#
# Table name: correspondence_types
#
#  id           :integer          not null, primary key
#  name         :string
#  abbreviation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  properties   :jsonb
#

require "rails_helper"

describe CorrespondenceType, type: :model do
  let(:foi) { create(:foi_correspondence_type) }
  let(:ico) { create(:ico_correspondence_type) }
  let(:sar) { create(:sar_correspondence_type) }
  let(:sar_ir) { create(:sar_internal_review_correspondence_type) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:abbreviation) }
  it { is_expected.to validate_presence_of(:escalation_time_limit) }
  it { is_expected.to validate_presence_of(:internal_time_limit) }
  it { is_expected.to validate_presence_of(:external_time_limit) }

  it {
    expect(described_class.new).to have_attributes(default_press_officer: nil,
                                                   default_private_officer: nil)
  }

  describe ".ico" do
    it "finds the ICO correspondence type" do
      ico = find_or_create :ico_correspondence_type
      expect(described_class.ico).to eq ico
    end
  end

  describe ".offender_sar" do
    it "finds the Offender SAR correspondence type" do
      offender_sar = find_or_create :offender_sar_correspondence_type
      expect(described_class.offender_sar).to eq offender_sar
    end
  end

  describe ".offender_sar_complaint" do
    it "finds the Offender SAR Complaint correspondence type" do
      offender_sar_complaint = find_or_create :offender_sar_complaint_correspondence_type
      expect(described_class.offender_sar_complaint).to eq offender_sar_complaint
    end
  end

  describe ".sar_internal_review" do
    it "finds the SAR Internal Review correspondence type" do
      sar_internal_review = find_or_create :sar_internal_review_correspondence_type
      expect(described_class.sar_internal_review).to eq sar_internal_review
    end
  end

  describe "teams" do
    it "lists teams that can handle this correspondence type" do
      ct1    = create(:correspondence_type, name: "ct1", abbreviation: "ct1")
      ct2    = create(:correspondence_type, name: "ct2", abbreviation: "ct2")
      team1a = create(:business_unit, correspondence_types: [ct1])
      team1b = create(:business_unit, correspondence_types: [ct1])
      _team2 = create(:business_unit, correspondence_types: [ct2])
      expect(ct1.teams).to eq [team1a, team1b]
    end
  end

  describe "deadline_calculator_class" do
    it { is_expected.to validate_presence_of(:deadline_calculator_class) }

    it "allows the value CalendarDays" do
      ct = described_class.new name: "Calendar Days Test",
                               abbreviation: "CDT",
                               escalation_time_limit: 1,
                               internal_time_limit: 1,
                               external_time_limit: 1,
                               deadline_calculator_class: "CalendarDays"
      expect(ct).to be_valid
    end

    it "allows the value BusinessDays" do
      ct = described_class.new name: "Business Days Test",
                               abbreviation: "BDT",
                               escalation_time_limit: 1,
                               internal_time_limit: 1,
                               external_time_limit: 1,
                               deadline_calculator_class: "BusinessDays"
      expect(ct).to be_valid
    end

    it "does not allow other values" do
      expect {
        described_class.new name: "Invalid Class Test",
                            abbreviation: "IDT",
                            escalation_time_limit: 1,
                            internal_time_limit: 1,
                            external_time_limit: 1,
                            deadline_calculator_class: "Invalid Class"
      }.to raise_error(ArgumentError)
    end
  end

  describe "#by_report_category" do
    let(:cts) { described_class.by_report_category }

    it "returns only those correspondence types where report_category_name is present" do
      expect(described_class.all.size).to be > 2
      expect(cts.size).to eq 5
    end

    it "returns them in alphabetic order of report category name" do
      expect(cts.map(&:report_category_name)).to eq [
        "FOI report",
        "Offender SAR Complaint report",
        "Offender SAR report",
        "SAR report",
        "SAR report",
      ]
    end
  end

  describe "#sub_classes" do
    it "returns FOI sub-classes" do
      expect(foi.sub_classes).to eq [Case::FOI::Standard,
                                     Case::FOI::TimelinessReview,
                                     Case::FOI::ComplianceReview]
    end

    it "returns ICO sub-classes" do
      expect(ico.sub_classes).to eq [Case::ICO::FOI,
                                     Case::ICO::SAR]
    end

    it "returns SAR sub-classes" do
      expect(sar.sub_classes).to eq [Case::SAR::Standard]
    end

    it "returns SAR_INTERNAL_REVIEW sub-classes" do
      expect(sar_ir.sub_classes).to eq [Case::SAR::InternalReview]
    end
  end

  describe "#display_order" do
    it "has a display_order order of nil" do
      ct = described_class.new name: "Business Days Test",
                               abbreviation: "BDT",
                               escalation_time_limit: 1,
                               internal_time_limit: 1,
                               external_time_limit: 1,
                               deadline_calculator_class: "BusinessDays"
      expect(ct.display_order).to eq nil
    end
  end
end
