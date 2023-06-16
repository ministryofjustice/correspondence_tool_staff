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
  RSpec.describe Exemption, type: :model do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_presence_of(:sequence_id) }
    it { is_expected.to validate_presence_of(:subtype) }

    context "scopes" do
      before(:all) do
        @ncnd_1 = create :exemption, :ncnd
        @abs_1 = create :exemption, :absolute, abbreviation: "abs1", name: "Absolute 1"
        @abs_2 = create :exemption, :absolute, abbreviation: "abs2", name: "Absolute 3"
        @qual_1 = create :exemption, :qualified, abbreviation: "qual1", name: "Qualified 1"
        @qual_2 = create :exemption, :qualified, abbreviation: "qual2", name: "Qualified 2"
      end

      after(:all) { CaseClosure::Metadatum.delete_all }

      describe ".ncnd" do
        it "returns only records of subtype ncnd" do
          expect(described_class.ncnd).to eq([@ncnd_1])
        end
      end

      describe ".absolute" do
        it "returns only records of subtype absolute" do
          expect(described_class.absolute).to match_array([@abs_1, @abs_2])
        end
      end

      describe ".qualified" do
        it "returns only records of subtype qualified" do
          expect(described_class.qualified).to match_array([@qual_1, @qual_2])
        end
      end

      describe "ncnd?" do
        it "returns true for ncnds" do
          expect(@ncnd_1.ncnd?).to be true
        end

        it "returns false for other subtypes" do
          expect(@qual_1.ncnd?).to be false
        end
      end

      describe ".method_missing" do
        context "method name is a section number" do
          it "queries the record by abbreviation" do
            arel = double "ActiveRecord Arel query result"
            expect(described_class).to receive(:where).with(abbreviation: "policy").and_return(arel)
            expect(arel).to receive(:first).and_return "policy exemption record"
            expect(described_class.s35).to eq "policy exemption record"
          end
        end

        context "method name is not an section number" do
          it "raises NoMethodError" do
            expect {
              described_class.s99
            }.to raise_error NoMethodError
          end
        end
      end
    end
  end
end
