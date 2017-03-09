# == Schema Information
#
# Table name: case_closure_metadata
#
#  id           :integer          not null, primary key
#  type         :string
#  subtype      :string
#  name         :string
#  abbreviation :string
#  sequence_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

module CaseClosure
  RSpec.describe Exemption, type: :model do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:abbreviation) }
    it { should validate_presence_of(:sequence_id) }
    it { should validate_presence_of(:subtype) }

    context 'scopes' do
      before(:all) do
        @ncnd_1 = create :exemption, :ncnd
        @ncnd_2 = create :exemption, :ncnd
        @abs_1 = create :exemption, :absolute
        @abs_2 = create :exemption, :absolute
        @qual_1 = create :exemption, :qualified
        @qual_2 = create :exemption, :qualified
      end

      after(:all) { CaseClosure::Metadatum.delete_all }

      describe '.ncnd' do
        it 'returns only records of subtype ncnd' do
          expect(Exemption.ncnd).to eq([@ncnd_1, @ncnd_2])
        end
      end

      describe '.absolute' do
        it 'returns only records of subtype absolute' do
          expect(Exemption.absolute).to eq([@abs_1, @abs_2])
        end
      end

      describe '.qualified' do
        it 'returns only records of subtype qualified' do
          expect(Exemption.qualified).to eq([@qual_1, @qual_2])
        end
      end
    end

  end
end
