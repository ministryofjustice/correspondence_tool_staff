# == Schema Information
#
# Table name: team_properties
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  key        :string
#  value      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

describe TeamProperty do


  context 'validation' do
    context 'duplicate value for team and key' do
      it 'raises if a duplicate value for same id and key is inserted' do
        TeamProperty.create!(team_id: 22, key: 'area', value: 'xyz')
        tp = TeamProperty.new(team_id: 22, key: 'area', value: 'xyz')
        expect(tp).not_to be_valid
        expect(tp.errors[:value]).to eq ['xyz is not unique in team and key']
      end
    end

    context 'invalid key' do
      it 'errors if key not a VALID_KEY' do
        tp = TeamProperty.new(key: 'xxxx', value: 'xxxx')
        expect(tp).not_to be_valid
        expect(tp.errors[:key]).to eq [ 'xxxx is not a valid key']
      end
    end
  end

end
