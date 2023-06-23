# == Schema Information
#
# Table name: linked_cases
#
#  id             :integer          not null, primary key
#  case_id        :integer          not null
#  linked_case_id :integer          not null
#  type           :string           default("related")
#

require "rails_helper"

describe LinkedCase do
  let(:foi)       { create :case }
  let(:other_foi) { create :case }
  let(:sar)       { create :sar_case }

  it "creates reverse links automatically" do
    expect {
      described_class.create(case: foi, linked_case: other_foi)
    }.to change(described_class, :count).by(2)
    expect(described_class.first.case_id).to eq foi.id
    expect(described_class.first.linked_case_id).to eq other_foi.id
    expect(described_class.first).to be_related

    expect(described_class.last.case_id).to eq other_foi.id
    expect(described_class.last.linked_case_id).to eq foi.id
    expect(described_class.last).to be_related
  end

  it "destroys reverse links automatically" do
    link = described_class.create!(case: foi, linked_case: other_foi)
    expect(described_class.first.case_id).to eq foi.id
    expect(described_class.last.case_id).to eq other_foi.id

    expect {
      link.destroy
    }.to change(described_class, :count).by(-2)
    expect(described_class.all).to be_empty
  end

  describe "#linked_case" do
    context "when FOI case" do
      it "can link to a FOI case" do
        case_link = described_class.create!(case: foi, linked_case: other_foi)
        expect(case_link).to be_valid
      end

      it "cannot be linked to itself" do
        case_link = described_class.create(case: foi, linked_case: foi) # rubocop:disable Rails/SaveBang
        expect(case_link).not_to be_valid
        expect(case_link.errors[:linked_case])
          .to eq ["cannot link to the same case"]
      end

      it "cannot link to a SAR case" do
        case_link = described_class.create(case: foi, linked_case: sar) # rubocop:disable Rails/SaveBang
        expect(case_link).not_to be_valid
        expect(case_link.errors[:linked_case])
          .to eq ["cannot link a FOI case to a Non-offender SAR as a related case"]
      end
    end
  end

  describe "#linked_case_number" do
    it "finds linked case by number and assigns to linked_case" do
      case_link = described_class.create!(case: foi, linked_case_number: other_foi.number)
      expect(case_link).to be_valid
      expect(case_link.linked_case).to eq other_foi
    end
  end

  context "when soft deleted cases" do
    let(:foi)         { create :case, name: "foi" }
    let(:second_foi)  { create :case, name: "second_foi" }
    let(:third_foi)   { create :case, name: "third_foi" }
    let(:manager)     { create :manager }

    before do
      described_class.create!(case: foi, linked_case: second_foi)
      described_class.create!(case: foi, linked_case: third_foi)
    end

    it "does not return linked cases which have been soft deleted" do
      expect(foi.linked_cases).to match_array([second_foi, third_foi])
      second_foi.related_cases.destroy(foi)
      CaseDeletionService.new(manager, second_foi, reason_for_deletion: "Just do it").call
      expect(foi.reload.linked_cases).to eq [third_foi]
    end

    it "is still valid even after a linked case has been deleted" do
      CaseDeletionService.new(manager, second_foi, reason_for_deletion: "Just do it").call
      expect(foi).to be_valid
    end
  end
end
