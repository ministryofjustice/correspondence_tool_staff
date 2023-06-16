# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

require "rails_helper"

describe Case::ICO::Base do
  let(:kase) { described_class.new }

  describe "search" do
    before :all do
      @case_a = create :accepted_ico_foi_case,
                       ico_reference_number: "ICOREF1",
                       ico_officer_name: "Bryan Adams"
      @case_b = create :accepted_ico_foi_case,
                       ico_reference_number: "ICOREF2",
                       ico_officer_name: "Douglas Adams"
      @case_a.update_index
      @case_b.update_index
    end

    after :all do
      DbHousekeeping.clean
    end

    it "returns case with the matching ICO reference number" do
      expect(Case::Base.search("ICOREF1")).to match_array [@case_a]
    end

    it "returns case with with the matching ICO officer" do
      expect(Case::Base.search("Douglas")).to match_array [@case_b]
    end
  end

  describe ".type_abbreviation" do
    subject { described_class.type_abbreviation }

    it { is_expected.to eq "ICO" }
  end

  describe "ico_officer_name attribute" do
    it { is_expected.to validate_presence_of(:ico_officer_name) }
  end

  describe "ico_reference_number attribute" do
    it { is_expected.to validate_presence_of(:ico_reference_number) }
  end

  describe "ico_decision enum" do
    it { is_expected.to have_enum(:ico_decision).with_values %w[upheld overturned] }
  end

  describe "message attribute" do
    it { is_expected.to validate_presence_of(:message) }
  end

  describe "external_deadline attribute" do
    it { is_expected.to validate_presence_of(:external_deadline) }

    it "is assignable by year, month and day" do
      kase.external_deadline_yyyy = "2018"
      kase.external_deadline_mm   = "1"
      kase.external_deadline_dd   = "12"
      expect(kase.external_deadline).to eq Date.new(2018, 1, 12)
    end

    it "cannot be before than received_date" do
      kase.update!(
        received_date: Time.zone.today,
        external_deadline: Time.zone.today - 1.day,
      )
      expect(kase).not_to be_valid
      expect(kase.errors[:external_deadline])
        .to eq ["cannot be before date received"]
    end

    it "cannot be more than a year past received_date" do
      kase.update!(
        received_date: Time.zone.today,
        external_deadline: Time.zone.today + 1.year + 1.day,
      )
      expect(kase).not_to be_valid
      expect(kase.errors[:external_deadline])
        .to eq ["cannot be more than a year past the date received"]
    end
  end

  describe "internal_deadline attribute" do
    it "is assignable by year, month and day" do
      kase.internal_deadline_yyyy = "2018"
      kase.internal_deadline_mm   = "1"
      kase.internal_deadline_dd   = "12"
      expect(kase.internal_deadline).to eq Date.new(2018, 1, 12)
    end

    context "on update" do
      let(:kase) { create(:ico_foi_case) }

      it { is_expected.to validate_presence_of(:internal_deadline).on(:update) }

      it "cannot be before received_date" do
        kase.update!(
          received_date: Time.zone.today,
          internal_deadline: Time.zone.today - 1.day,
        )
        expect(kase).not_to be_valid
        expect(kase.errors[:internal_deadline])
          .to eq ["cannot be before date received"]
      end

      it "cannot be after than external_deadline" do
        kase.update!(
          external_deadline: Time.zone.today + 20.days,
          internal_deadline: Time.zone.today + 21.days,
        )
        expect(kase).not_to be_valid
        expect(kase.errors[:internal_deadline])
          .to eq ["cannot be after final deadline"]
      end
    end
  end

  describe "original_case association" do
    it {
      expect(subject).to have_one(:original_case)
                  .through(:original_case_link)
                  .source(:linked_case)
    }

    it "validates that the case can be associated as an original case" do
      linked_case = create(:ico_foi_case)
      ico = build_stubbed(:ico_foi_case, original_case: linked_case)
      expect(ico).not_to be_valid
      expect(ico.errors[:original_case])
        .to eq ["cannot link a ICO Appeal - FOI case to a ICO Appeal - FOI as a original case"]
    end

    it "validates that a case isn't both original and related" do
      foi = create(:foi_case)
      ico = build_stubbed(:ico_foi_case, original_case: foi, related_cases: [foi])
      expect(ico).not_to be_valid
      expect(ico.errors[:linked_cases])
        .to eq ["already linked as the original case"]
    end

    it "validates that original case is present" do
      ico = create(:ico_foi_case)
      ico.original_case = nil
      ico.valid?
      expect(ico.errors[:original_case]).to eq ["can't be blank"]
    end
  end

  describe "original_case_link association" do
    it {
      expect(subject).to have_one(:original_case_link)
                  .class_name("LinkedCase")
                  .with_foreign_key("case_id")
    }
  end

  describe "#original_case_id" do
    it "finds case and assigns to original_case" do
      foi = create(:foi_case)
      ico = build_stubbed(:ico_foi_case, original_case: nil)
      ico.original_case_id = foi.id
      expect(ico).to be_valid
      expect(ico.original_case).to eq foi
    end
  end

  describe "case_links association" do
    it "validates that the original case is not already related" do
      foi = create(:foi_case)
      ico = create(:ico_foi_case, related_cases: [foi])
      expect(ico).to be_valid
      ico.original_case = foi
      ico.save!
      expect(ico).not_to be_valid
    end
  end

  describe "#requires_flag_for_disclosure_specialists?" do
    it "returns false" do
      kase = create :ico_foi_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be false
    end
  end

  describe "#name=" do
    it "raises a ReadOnly error" do
      expect {
        kase.name = "something new"
      }.to raise_error(StandardError,
                       "name attribute is read-only for ICO cases")
    end
  end

  describe "received_date attribute" do
    it { is_expected.to validate_presence_of(:received_date) }

    it "is assignable by year, month and day" do
      kase.received_date_yyyy = "2018"
      kase.received_date_mm   = "3"
      kase.received_date_dd   = "12"
      expect(kase.received_date).to eq Date.new(2018, 3, 12)
    end

    it "cannot be more than 10 years in the past" do
      kase.received_date = Time.zone.today - 10.years - 1.day
      expect(kase).not_to be_valid
      expect(kase.errors[:received_date])
        .to eq ["cannot be over 10 years in the past"]
    end

    it "cannot be in the future" do
      kase.received_date = Time.zone.today + 1.day
      expect(kase).not_to be_valid
      expect(kase.errors[:received_date])
        .to eq ["cannot be in the future."]
    end
  end

  describe "#subject" do
    it "returns the subject from the original case" do
      foi = create(:foi_case)
      ico = create(:ico_foi_case, original_case: foi)

      expect(ico.subject).to eq foi.subject
    end
  end

  describe "#subject=" do
    it "raises a ReadOnly error" do
      foi = create(:foi_case)
      ico = create(:ico_foi_case, original_case: foi)

      expect {
        ico.subject = "something new"
      }.to raise_error(StandardError,
                       "subject attribute is read-only for ICO cases")
    end
  end

  describe ".search" do
    it "finds cases by ico officer name" do
      ico = create(:ico_foi_case, ico_officer_name: "Leeroy")
      _other_ico = create(:ico_foi_case, ico_officer_name: "Fred")
      Case::Base.update_all_indexes

      expect(Case::Base.search("Leeroy")).to eq [ico]
    end

    it "finds cases by ico reference number" do
      ico = create(:ico_foi_case, ico_reference_number: "8888")
      _other_ico = create(:ico_foi_case, ico_reference_number: "11")
      Case::Base.update_all_indexes

      expect(Case::Base.search("8888")).to eq [ico]
    end
  end

  describe "#prepared_for_respond?" do
    let(:foi)   { create(:foi_case) }
    let(:ico)   { create(:ico_foi_case, original_case: foi) }

    context "default state" do
      it "is false" do
        expect(ico.prepared_for_respond?).to be false
      end
    end

    context "after being set to true" do
      it "is true" do
        ico.prepare_for_respond
        expect(ico.prepared_for_respond?).to be true
      end
    end
  end

  describe "updating deadlines" do
    it "uses the dates provided" do
      today = 0.business_days.ago.to_date
      kase = create(:ico_foi_case,
                    received_date: today,
                    internal_deadline: 10.business_days.after(today),
                    external_deadline: 20.business_days.after(today))
      expect(kase.received_date).to eq today
      expect(kase.internal_deadline).to eq 10.business_days.after(today)
      expect(kase.external_deadline).to eq 20.business_days.after(today)

      new_received_date = 5.business_days.ago.to_date
      kase.update!(received_date: new_received_date,
                   internal_deadline: 10.business_days.after(new_received_date),
                   external_deadline: 20.business_days.after(new_received_date))
      expect(kase.received_date).to eq new_received_date
      expect(kase.internal_deadline).to eq 10.business_days.after(new_received_date)
      expect(kase.external_deadline).to eq 20.business_days.after(new_received_date)
    end
  end
end
