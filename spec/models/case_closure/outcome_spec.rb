# == Schema Information
#
# Table name: case_closure_metadata
#
#  id                      :integer          not null, primary key
#  type                    :string
#  subtype                 :string
#  name                    :string
#  abbreviation            :string
#  sequence_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  requires_refusal_reason :boolean          default(FALSE)
#  requires_exemption      :boolean          default(FALSE)
#  active                  :boolean          default(TRUE)
#  omit_for_part_refused   :boolean          default(FALSE)
#

require "rails_helper"

module CaseClosure
  RSpec.describe Outcome, type: :model do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_presence_of(:sequence_id) }

    describe ".id_from_name" do
      it "returns the id when name exists in the database" do
        outcome = create :outcome
        expect(described_class.id_from_name(outcome.name)).to eq outcome.id
      end

      it "returns nil when no record with specified name" do
        expect(described_class.id_from_name("xxxxxxxx")).to be nil
      end
    end
  end
end
