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

describe Case::OverturnedICO::Base do
  let(:original_case) do
    create :sar_case,
           subject: "My original SAR case",
           delivery_method: "sent_by_post"
  end
  let(:ico_appeal)        { create :ico_sar_case, original_case:, ico_officer_name: "Dan Dare" }
  let(:overturned_ico)    do
    create :overturned_ico_sar,
           original_ico_appeal_id: ico_appeal.id,
           original_case_id: original_case.id
  end

  describe "delivery method validations" do
    context "when send_by_email" do
      it "is invalid if no email address specified" do
        overturned_ico.email = nil
        expect(overturned_ico).not_to be_valid
        expect(overturned_ico.errors[:email]).to eq ["cannot be blank"]
      end
    end

    context "when send by post" do
      it "is invalid if no postal address specified" do
        overturned_ico.reply_method = "send_by_post"
        expect(overturned_ico).not_to be_valid
        expect(overturned_ico.errors[:postal_address]).to eq ["cannot be blank"]
      end
    end
  end

  describe "ico_reference_number" do
    it "delegates to the origin ICO Appeal" do
      expect(overturned_ico).to delegate_method(:ico_reference_number)
                                  .to(:original_ico_appeal)
    end
  end

  describe "ico_decision" do
    it "delegates to the origin ICO Appeal" do
      expect(overturned_ico).to delegate_method(:ico_decision)
                                  .to(:original_ico_appeal)
    end
  end

  describe "ico_decision_comment" do
    it "delegates to the origin ICO Appeal" do
      expect(overturned_ico).to delegate_method(:ico_decision_comment)
                                  .to(:original_ico_appeal)
    end
  end

  describe "date_ico_decision_received" do
    it "delegates to the origin ICO Appeal" do
      expect(overturned_ico).to delegate_method(:date_ico_decision_received)
                                  .to(:original_ico_appeal)
    end
  end

  describe "ico_decision_attachments" do
    it "delegates to the origin ICO Appeal" do
      expect(overturned_ico).to delegate_method(:ico_decision_attachments)
                                  .to(:original_ico_appeal)
    end
  end

  describe "#subject" do
    it "returns the subject from the original case" do
      expect(overturned_ico.subject).to eq "My original SAR case"
    end
  end

  describe "#delivery_method" do
    context "when no delivery method set on this overturned record" do
      it "gets the delivery method from the original case" do
        overturned_ico[:delivery_method] = nil
        expect(overturned_ico.delivery_method).to eq "sent_by_post"
      end
    end

    context "when delivery method set on this overturned record" do
      it "uses the delivery method on this record and not the original case" do
        overturned_ico[:delivery_method] = "sent_by_email"
        expect(overturned_ico.delivery_method).to eq "sent_by_email"
      end
    end
  end

  describe "#delivery_method=" do
    context "when using attribute assignement" do
      it "sets the delivery method on this overturned record and leaves the original case untouched" do
        overturned_ico.delivery_method = "sent_by_email"
        overturned_ico.save!
        expect(overturned_ico[:delivery_method]).to eq "sent_by_email"
        expect(original_case.delivery_method).to eq "sent_by_post"
      end
    end

    context "when using update" do
      it "sets the delivery method on this overturned record and leaves the original case untouched" do
        overturned_ico.update!(delivery_method: "sent_by_email")
        expect(overturned_ico[:delivery_method]).to eq "sent_by_email"
        expect(original_case.delivery_method).to eq "sent_by_post"
      end
    end
  end

  describe "#ico_officer_name" do
    it "copies from original_ico_appeal" do
      expect(overturned_ico.ico_officer_name).to eq "Dan Dare"
    end
  end

  describe "#ico_officer_name=" do
    before { overturned_ico.ico_officer_name = "Albert Fitzwilliam Digby" }

    it "changes the name" do
      expect(overturned_ico.ico_officer_name).to eq "Albert Fitzwilliam Digby"
    end

    it "does not change the ico officer name on the original appeal" do
      expect(overturned_ico.original_ico_appeal.ico_officer_name).to eq "Dan Dare"
    end

    it "is not valid if not set" do
      overturned_ico.ico_officer_name = ""
      expect(overturned_ico).not_to be_valid
      expect(overturned_ico.errors[:ico_officer_name]).to include("cannot be blank")
    end
  end
end
