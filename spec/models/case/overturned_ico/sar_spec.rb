# == Schema Information
#
# Table name: cases
#
#  id                       :integer          not null, primary key
#  name                     :string
#  email                    :string
#  message                  :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  received_date            :date
#  postal_address           :string
#  subject                  :string
#  properties               :jsonb
#  requester_type           :enum
#  number                   :string           not null
#  date_responded           :date
#  outcome_id               :integer
#  refusal_reason_id        :integer
#  current_state            :string
#  last_transitioned_at     :datetime
#  delivery_method          :enum
#  workflow                 :string
#  deleted                  :boolean          default(FALSE)
#  info_held_status_id      :integer
#  type                     :string
#  appeal_outcome_id        :integer
#  dirty                    :boolean          default(FALSE)
#  reason_for_deletion      :string
#  user_id                  :integer          default(-100), not null
#  reason_for_lateness_id   :bigint
#  reason_for_lateness_note :string
#

require "rails_helper"

describe Case::OverturnedICO::SAR do
  let(:new_case)       { described_class.new }
  let(:creator)        { create(:user, :orphan) }

  # TODO: Clean up factories, I think we're creating at on of extra cases we don't need here
  let(:sar_ico_appeal) { create :ico_sar_case }
  let(:sar)            { find_or_create :sar_correspondence_type }

  describe ".type_abbreviation" do
    it "returns the correct abbreviation" do
      expect(described_class.type_abbreviation).to eq "OVERTURNED_SAR"
    end
  end

  describe "validations" do
    context "when all mandatory fields specified" do
      context "and created in a factory" do
        it "is valid" do
          kase = create :overturned_ico_sar
          expect(kase).to be_valid
        end
      end

      context "and created with params" do
        it "is valid" do
          received = Time.zone.today
          deadline = 1.month.from_now
          params = ActionController::Parameters.new(
            {
              "original_case_id" => sar_ico_appeal.original_case.id.to_s,
              "original_ico_appeal_id" => sar_ico_appeal.id.to_s,
              "received_date_dd" => received.day.to_s,
              "received_date_mm" => received.month.to_s,
              "received_date_yyyy" => received.year.to_s,
              "external_deadline_dd" => deadline.day.to_s,
              "external_deadline_mm" => deadline.month.to_s,
              "external_deadline_yyyy" => deadline.year.to_s,
              "reply_method" => "send_by_email",
              "email" => "stephen@stephenrichards.eu",
              "ico_officer_name" => "Dan Dare",
            },
          ).to_unsafe_hash
          params[:creator] = creator
          kase = described_class.new(params)
          expect(kase).to be_valid
        end
      end
    end

    describe "received_date" do
      it "errors if blank" do
        expect(new_case).not_to be_valid
        expect(new_case.errors[:received_date]).to eq ["cannot be blank"]
      end

      it "errors if in the future" do
        new_case.received_date = 1.day.from_now
        expect(new_case).not_to be_valid
        expect(new_case.errors[:received_date]).to eq ["cannot be in the future"]
      end

      context "when too far in the past" do
        context "and new record" do
          it "errors" do
            new_case.received_date = 41.days.ago
            expect(new_case).not_to be_valid
            expect(new_case.errors[:received_date]).to eq ["of decision from ICO must be within 40 days of today"]
          end
        end

        context "when createed" do
          it "errors" do
            record = described_class.create(received_date: 41.days.ago) # rubocop:disable Rails/SaveBang
            expect(record.errors[:received_date]).to eq ["of decision from ICO must be within 40 days of today"]
          end
        end

        context "when existing record" do
          it "does not error" do
            record = described_class.create(received_date: 41.days.ago) # rubocop:disable Rails/SaveBang
            allow(record).to receive(:new_record?).and_return(false)
            record.valid?
            expect(record.errors[:received_date]).to be_empty
          end
        end
      end

      it "does not error if in the expected range" do
        new_case.received_date = 3.days.ago
        new_case.valid?
        expect(new_case.errors[:received_date]).to be_empty
      end
    end

    describe "external_deadline" do
      it "errors if blank" do
        expect(new_case).not_to be_valid
        expect(new_case.errors[:external_deadline]).to eq ["cannot be blank"]
      end

      context "when in the past" do
        context "and new record" do
          it "errors" do
            new_case.external_deadline = 1.day.ago
            expect(new_case).not_to be_valid
            expect(new_case.errors[:external_deadline]).to eq ["cannot be in the past"]
          end
        end

        context "and existing  record" do
          it "does not error" do
            new_case.external_deadline = 3.days.ago
            allow(new_case).to receive(:new_record?).and_return(false)
            new_case.valid?
            expect(new_case.errors[:external_deadline]).to be_empty
          end
        end
      end

      context "when in the future" do
        context "and too far in the future" do
          it "errors" do
            new_case.external_deadline = 51.days.from_now
            expect(new_case).not_to be_valid
            expect(new_case.errors[:external_deadline]).to eq ["is too far in the future"]
          end
        end

        context "when within 50 days from now" do
          it "does not error" do
            new_case.external_deadline = 49.days.from_now
            new_case.valid?
            expect(new_case.errors[:external_deadline]).to be_empty
          end
        end
      end
    end

    describe "original_ico_appeal_id" do
      context "when blank" do
        it "errors" do
          expect(new_case).not_to be_valid
          expect(new_case.errors[:original_ico_appeal]).to eq ["cannot be blank"]
        end
      end

      context "when Case::ICO::SAR" do
        it "is valid" do
          ico_sar = create :ico_sar_case
          new_case.original_ico_appeal = ico_sar
          new_case.valid?
          expect(new_case.errors[:original_ico_appeal]).to be_empty
        end
      end

      context "when Case::ICO::FOI" do
        it "is invalid" do
          foi = create :case
          new_case.original_ico_appeal = foi
          new_case.valid?
          expect(new_case.errors[:original_ico_appeal]).to eq ["is not an ICO appeal for a SAR case"]
        end
      end

      context "when Case::SAR" do
        it "is invalid" do
          sar = create :sar_case
          new_case.original_ico_appeal = sar
          new_case.valid?
          expect(new_case.errors[:original_ico_appeal]).to eq ["is not an ICO appeal for a SAR case"]
        end
      end
    end

    describe "original_case_id" do
      context "when blank" do
        before do
          @my_thing = []
        end

        it "errors" do
          expect(new_case).not_to be_valid
          expect(new_case.errors[:original_case]).to eq ["cannot be blank"]
        end
      end

      context "when Case::SAR" do
        it "is valid" do
          sar = create :sar_case
          new_case.original_case_id = sar.id
          new_case.valid?
          expect(new_case.errors[:original_case_id]).to be_empty
        end

        it "is invalid" do
          foi = create :case
          new_case.original_case = foi
          new_case.valid?
          expect(new_case.errors[:original_case]).to eq ["cannot link a Overturned ICO appeal for non-offender SAR case to a FOI as a original case"]
        end
      end

      context "when Case::ICO::SAR" do
        it "is invalid" do
          ico_sar = create :ico_sar_case
          new_case.original_case = ico_sar
          new_case.valid?
          expect(new_case.errors[:original_case]).to eq ["cannot link a Overturned ICO appeal for non-offender SAR case to a ICO Appeal - SAR as a original case"]
        end
      end
    end
  end

  context "when setting deadlines" do
    it "sets the internal deadline from the external deadline" do
      Timecop.freeze(2018, 7, 23, 10, 0, 0) do
        kase = create :overturned_ico_sar,
                      received_date: Time.zone.today,
                      external_deadline: 1.month.from_now.to_date
        expect(kase.internal_deadline).to eq 20.business_days.before(1.month.from_now).to_date
      end
    end

    it "sets the escalation deadline to the received_date" do
      kase = create :overturned_ico_sar,
                    received_date: 0.business_days.ago,
                    external_deadline: 30.business_days.from_now
      expect(kase.escalation_deadline).to eq kase.created_at.to_date
    end
  end

  describe "#link_related_cases" do
    let(:link_case_1)             { create :sar_case }
    let(:link_case_2)             { create :sar_case }
    let(:link_case_3)             { create :sar_case }
    let(:original_ico_appeal)     { create(:closed_ico_sar_case, :overturned_by_ico) }
    let(:kase) do
      create :overturned_ico_sar,
             original_ico_appeal:,
             original_case: original_ico_appeal.original_case,
             received_date: Time.zone.today,
             external_deadline: 1.month.from_now.to_date
    end

    before do
      kase.original_case.linked_cases << link_case_1
      kase.original_case.linked_cases << link_case_2

      kase.original_ico_appeal.linked_cases << link_case_2
      kase.original_ico_appeal.linked_cases << link_case_3
    end

    it "links all the cases linked to the original case and the original_ico_appeal" do
      kase.link_related_cases

      expect(kase.linked_cases).to match_array [
        kase.original_case,
        kase.original_ico_appeal,
        link_case_1,
        link_case_2,
        link_case_3,
      ]
    end

    it "links the overturned case to the original appeal" do
      kase.link_related_cases
      expect(kase.original_ico_appeal.linked_cases).to include(kase)
    end

    it "links the overturned case to the original case" do
      kase.link_related_cases
      expect(kase.original_case.linked_cases).to include(kase)
    end
  end

  describe "#correspondence_type_for_business_unit_assignment" do
    it "returns SAR correspondence type" do
      expect(new_case.correspondence_type_for_business_unit_assignment)
        .to eq sar
    end
  end
end
