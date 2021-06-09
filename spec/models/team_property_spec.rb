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

    context 'uniqueness of lead key by team' do
      before(:each) do
        TeamProperty.where(team_id: 33).each do | item | 
          item.destroy
        end
      end
  
      it 'does not error if one lead key created per team' do
        tp = TeamProperty.new(team_id: 33, key: 'lead', value: 'xxxx')
        expect(tp).to be_valid
      end

      it 'errors if two lead keys for same team' do
        TeamProperty.create!(team_id: 33, key: 'lead', value: 'xxxx')
        tp = TeamProperty.new(team_id: 33, key: 'lead', value: 'zzzz')
        expect(tp).not_to be_valid
        expect(tp.errors[:key]).to include('lead already exists for this team')
      end
    end
  end

end
