# == Schema Information
#
# Table name: data_requests
#
#  id                      :integer          not null, primary key
#  case_id                 :integer          not null
#  user_id                 :integer          not null
#  location                :string
#  request_type            :enum             not null
#  date_requested          :date             not null
#  cached_date_received    :date
#  cached_num_pages        :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  request_type_note       :text             default(""), not null
#  date_from               :date
#  date_to                 :date
#  completed               :boolean          default(FALSE), not null
#  contact_id              :bigint
#  email_branston_archives :boolean          default(FALSE)
#  data_request_area_id    :bigint
#
require "rails_helper"

RSpec.describe DataRequest, type: :model do
  describe "#create" do
    context "with valid params" do
      subject(:data_request) do
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build_stubbed(:user),
          request_type: "all_prison_records",
          request_type_note: "",
          date_requested: Date.current,
        )
      end

      it { is_expected.to be_valid }

      it "has 0 cached_num_pages by default" do
        expect(data_request.cached_num_pages).to eq 0
      end

      it "sets date_requested to today by default" do
        data_request.save!
        expect(data_request.date_requested).to eq Date.current
      end

      it "uses supplied date_requested if present" do
        new_data_request = data_request.clone
        new_data_request.date_requested = Date.new(1992, 7, 11)
        new_data_request.save!
        expect(new_data_request.date_requested).to eq Date.new(1992, 7, 11)
      end

      it "uses supplied date received if present" do
        new_data_request = data_request.clone
        new_data_request.completed = true
        new_data_request.cached_date_received = Date.new(2021, 8, 9)
        new_data_request.save!
        expect(new_data_request.cached_date_received).to eq Date.new(2021, 8, 9)
      end

      it "defaults to in progress" do
        expect(data_request.completed).to eq false
        expect(data_request.status).to eq :in_progress
      end
    end

    describe "#data_request_types" do
      let(:data_request) { create(:data_request, data_request_area:) }

      context "when data_request_area_type is 'branston'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "branston") }

        it "returns the BRANSTON_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::BRANSTON_DATA_REQUEST_TYPES)
        end
      end

      context "when data_request_area_type is 'branston_registry'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "branston_registry") }

        it "returns the BRANSTON_REGISTRY_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::BRANSTON_REGISTRY_DATA_REQUEST_TYPES)
        end
      end

      context "when data_request_area_type is 'mappa'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "mappa") }

        it "returns the MAPPA_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::MAPPA_DATA_REQUEST_TYPES)
        end
      end

      context "when data_request_area_type is 'prison'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "prison") }

        it "returns the PRISON_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::PRISON_DATA_REQUEST_TYPES)
        end
      end

      context "when data_request_area_type is 'probation'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "probation") }

        it "returns the PROBATION_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::PROBATION_DATA_REQUEST_TYPES)
        end
      end

      context "when data_request_area_type is 'security'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "security") }

        it "returns the SECURITY_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::SECURITY_DATA_REQUEST_TYPES)
        end
      end

      context "when data_request_area_type is 'other_department'" do
        let(:data_request_area) { create(:data_request_area, data_request_area_type: "other_department") }

        it "returns the OTHER_DEPARTMENT_DATA_REQUEST_TYPES" do
          expect(data_request.data_request_types).to eq(DataRequest::OTHER_DEPARTMENT_DATA_REQUEST_TYPES)
        end
      end
    end

    describe "validation" do
      subject(:data_request) { build :data_request }

      it { is_expected.to be_valid }

      it "requires a request type" do
        invalid_values = ["", " ", nil]

        invalid_values.each do |bad_data|
          data_request.request_type = bad_data
          expect(data_request.valid?).to be false
        end
      end

      it "requires a creating user" do
        data_request.user = nil
        expect(data_request.valid?).to be false
      end

      it "requires a case" do
        data_request.offender_sar_case = nil
        expect(data_request.valid?).to be false
      end

      it "ensures cached_num_pages is a positive value only" do
        data_request.cached_num_pages = -10
        expect(data_request.valid?).to be false

        data_request.cached_num_pages = 6.5
        expect(data_request.valid?).to be false
      end
    end

    context "with date when data request is complete" do
      subject(:data_request) { build_stubbed(:data_request, completed: true) }

      it "required if the case is marked as completed" do
        data_request.cached_date_received = nil
        expect(data_request).not_to be_valid
        expect(data_request.errors[:cached_date_received]).to eq ["must be provided if request is complete"]
      end

      it "The value cannot be in the future" do
        data_request.cached_date_received = 1.day.from_now
        expect(data_request).not_to be_valid
        expect(data_request.errors[:cached_date_received]).to eq ["cannot be in the future"]
      end

      it "The value should be blank if data is not complete" do
        data_request.completed = false
        data_request.cached_date_received = 1.day.from_now
        expect(data_request).not_to be_valid
        expect(data_request.errors[:cached_date_received]).to eq ["should be blank if the request is not complete"]
      end
    end

    context "when request_type is other" do
      subject(:data_request) { build_stubbed(:data_request, request_type: "other", request_type_note: nil) }

      it "ensures the note is present" do
        expect(data_request).not_to be_valid
        expect(data_request.errors[:request_type_note]).to eq ["cannot be blank"]
      end
    end

    context "when both from and to date is set" do
      subject(:data_request) { build_stubbed(:data_request, date_from: 1.year.ago, date_to: 2.years.ago) }

      it "ensures the to date is after the from date" do
        expect(data_request).not_to be_valid
        expect(data_request.errors[:date_from]).to eq ["cannot be later than date to"]
      end
    end

    context "with note" do
      subject(:data_request) { build :data_request, :other }

      it { is_expected.to be_valid }

      it "has a note" do
        expect(data_request.request_type_note).to eq "Lorem ipsum"
      end
    end

    context "with date range" do
      subject(:data_request) { build :data_request, :with_date_range }

      it { is_expected.to be_valid }

      it "has date from and to" do
        expect(data_request.date_from).to eq Date.new(2018, 0o1, 0o1)
        expect(data_request.date_to).to eq Date.new(2018, 12, 31)
      end
    end

    context "with from date" do
      subject(:data_request) { build :data_request, :with_date_from }

      it { is_expected.to be_valid }
    end

    context "with to date" do
      subject(:data_request) { build :data_request, :with_date_to }

      it { is_expected.to be_valid }
    end
  end

  describe "#request_type" do
    context "with valid values" do
      it "does not error" do
        described_class.request_types.keys.each do |request_type|
          if request_type == "other"
            expect(build_stubbed(:data_request, request_type:, request_type_note: "other note")).to be_valid
          else
            expect(build_stubbed(:data_request, request_type:)).to be_valid
          end
        end
      end
    end

    context "with invalid value" do
      it "errors" do
        expect {
          build_stubbed(:data_request, request_type: "user")
        }.to raise_error ArgumentError
      end
    end

    context "when nil" do
      it "errors" do
        kase = build_stubbed(:data_request, request_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:request_type]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#clean_attributes" do
    subject(:data_request) { build :data_request }

    it "ensures string attributes do not have leading/trailing spaces" do
      data_request.request_type_note = "  a note"
      data_request.send(:clean_attributes)
      expect(data_request.request_type_note).to eq "A note"
    end

    it "ensures string attributes have the first letter capitalised" do
      data_request.request_type_note = "a note"
      data_request.send(:clean_attributes)
      expect(data_request.request_type_note).to eq "A note"
    end
  end

  describe "#status" do
    context "when data request is in progress" do
      let!(:data_request) { build_stubbed(:data_request) }

      it "returns completed" do
        expect(data_request.status).to eq :in_progress
      end
    end

    context "when data request is completed" do
      let!(:data_request) { build_stubbed(:data_request, :completed) }

      it "returns completed" do
        expect(data_request.status).to eq :completed
      end
    end
  end

  describe "scope completed" do
    let!(:data_request_in_progress) { create(:data_request) }
    let!(:data_request_completed) { create(:data_request, :completed, cached_date_received: Time.zone.today) }

    it "returns completed data requests" do
      expect(described_class.completed).to match_array [data_request_completed]
      expect(described_class.completed).not_to include data_request_in_progress
    end
  end

  describe "scope in_progress" do
    let!(:data_request_in_progress) { create(:data_request) }
    let!(:data_request_completed) { create(:data_request, :completed, cached_date_received: Time.zone.today) }

    it "returns in progress data requests" do
      expect(described_class.in_progress).to match_array [data_request_in_progress]
      expect(described_class.in_progress).not_to include data_request_completed
    end
  end

  describe "#request_dates_either_present?" do
    context "when no request dates available" do
      subject(:data_request) { build :data_request }

      it { expect(data_request.request_dates_either_present?).to eq false }
    end

    context "when from request date available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }

      it { expect(data_request.request_dates_either_present?).to eq true }
    end

    context "when to request date available" do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }

      it { expect(data_request.request_dates_either_present?).to eq true }
    end

    context "when both request dates available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }

      it { expect(data_request.request_dates_either_present?).to eq true }
    end
  end

  describe "#request_dates_both_present?" do
    context "when no request dates available" do
      subject(:data_request) { build :data_request }

      it { expect(data_request.request_dates_both_present?).to eq false }
    end

    context "when one request date available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }

      it { expect(data_request.request_dates_both_present?).to eq false }
    end

    context "when both request dates available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }

      it { expect(data_request.request_dates_both_present?).to eq true }
    end
  end

  describe "#request_date_from_only?" do
    context "when no request dates available" do
      subject(:data_request) { build :data_request }

      it { expect(data_request.request_date_from_only?).to eq false }
    end

    context "when from request date available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }

      it { expect(data_request.request_date_from_only?).to eq true }
    end

    context "when to request date available" do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }

      it { expect(data_request.request_date_from_only?).to eq false }
    end

    context "when both request dates available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }

      it { expect(data_request.request_date_from_only?).to eq false }
    end
  end

  describe "#request_date_to_only?" do
    context "when no request dates available" do
      subject(:data_request) { build :data_request }

      it { expect(data_request.request_date_to_only?).to eq false }
    end

    context "when from request date available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }

      it { expect(data_request.request_date_to_only?).to eq false }
    end

    context "when to request date available" do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }

      it { expect(data_request.request_date_to_only?).to eq true }
    end

    context "when both request dates available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }

      it { expect(data_request.request_date_to_only?).to eq false }
    end
  end

  describe "#request_dates_absent?" do
    context "when no request dates available" do
      subject(:data_request) { build :data_request }

      it { expect(data_request.request_dates_absent?).to eq true }
    end

    context "when from request date available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }

      it { expect(data_request.request_dates_absent?).to eq false }
    end

    context "when to request date available" do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }

      it { expect(data_request.request_dates_absent?).to eq false }
    end

    context "when both request dates available" do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }

      it { expect(data_request.request_dates_absent?).to eq false }
    end
  end
end
