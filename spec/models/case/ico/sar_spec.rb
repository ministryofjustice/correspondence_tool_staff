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

describe Case::ICO::SAR do
  let(:kase) { described_class.new }

  describe ".decorator_class" do
    subject { described_class.decorator_class }

    it { is_expected.to eq Case::ICO::SARDecorator }
  end

  describe "#original_case_type" do
    subject { kase.original_case_type }

    it { is_expected.to eq "SAR" }
  end

  describe "#has_overturn? and #lacks?" do
    let(:ico_sar_case) { create :closed_ico_sar_case }

    before { ico_sar_case.linked_cases << create(:sar_case) }

    context "when no overturn" do
      it "returns false" do
        expect(ico_sar_case.has_overturn?).to be false
        expect(ico_sar_case.lacks_overturn?).to be true
      end
    end

    context "when overturn exists" do
      before { create :overturned_ico_sar, original_ico_appeal: ico_sar_case }

      it "returns true" do
        expect(ico_sar_case.has_overturn?).to be true
        expect(ico_sar_case.lacks_overturn?).to be false
      end
    end
  end

  describe "#reset_responding_assignment_flag" do
    let(:ico_sar_case) { create :closed_ico_sar_case }

    before { ico_sar_case.linked_cases << create(:sar_case) }

    it "updates the responder assignment state to pending" do
      expect(ico_sar_case.responder_assignment.state).to eq "accepted"
      ico_sar_case.reset_responding_assignment_flag
      expect(ico_sar_case.responder_assignment.state).to eq "pending"
    end
  end

  describe "complaint outcome validation" do
    it "sar_complaint_outcome cannot be empty" do
      kase.prepare_for_recording_outcome
      kase.valid?
      expect(kase.errors).to include(:sar_complaint_outcome)
    end

    it "sar_complaint_outcome must be in COMPLAINT_OUTCOMES" do
      kase.prepare_for_recording_outcome
      kase.sar_complaint_outcome = "invalid_value"
      kase.valid?
      expect(kase.errors).to include(:sar_complaint_outcome)

      kase.sar_complaint_outcome = "sar_incorrectly_processed_now_responded_as_sar"
      kase.valid?
      expect(kase.errors).not_to include(:sar_complaint_outcome)
    end

    it "other_sar_complaint_outcome_note cannot empty when outcome is other" do
      kase.prepare_for_recording_outcome
      kase.sar_complaint_outcome = "other_outcome"
      kase.valid?
      expect(kase.errors).to include(:other_sar_complaint_outcome_note)

      kase.other_sar_complaint_outcome_note = "a reason"
      kase.valid?
      expect(kase.errors).not_to include(:other_sar_complaint_outcome_note)
    end
  end
end
