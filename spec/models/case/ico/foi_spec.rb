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

describe Case::ICO::FOI do
  let(:kase) { described_class.new }

  describe ".decorator_class" do
    subject { described_class.decorator_class }

    it { is_expected.to eq Case::ICO::FOIDecorator }
  end

  describe "#original_case_type" do
    subject { kase.original_case_type }

    it { is_expected.to eq "FOI" }
  end

  describe "#num_days_late_against_original_deadline" do
    let(:require_further_action_case) { create :require_further_action_ico_foi_case }

    it "is nil when 0 days late" do
      require_further_action_case.original_external_deadline = Time.zone.today
      expect(require_further_action_case.num_days_late_against_original_deadline).to be nil
    end

    it "is nil when not yet late for open case" do
      require_further_action_case.original_external_deadline = Time.zone.tomorrow
      expect(require_further_action_case.num_days_late_against_original_deadline).to be nil
    end

    it "returns correct number of days late for open case" do
      Timecop.freeze(Time.zone.local(2020, 9, 11, 9, 45, 33)) do
        tase = build_stubbed :require_further_action_ico_foi_case,
                             created_at: Time.zone.local(2020, 8, 1, 9, 45, 0o0),
                             received_date: Time.zone.local(2020, 8, 1, 9, 45, 33)
        tase.original_external_deadline = Time.zone.local(2020, 9, 4, 9, 0o0, 33)
        expect(tase.num_days_late_against_original_deadline).to eq 5
      end
    end

    it "returns correct number of days late for closed case" do
      Timecop.freeze(Date.new(2020, 9, 11)) do
        require_further_action_case.original_external_deadline = Date.new(2020, 9, 1)
        require_further_action_case.date_responded = Date.new(2020, 9, 10)
        expect(require_further_action_case.num_days_late_against_original_deadline).to eq 7
      end
    end
  end
end
