# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#

require 'rails_helper'

RSpec.describe Team, type: :model do
  it 'can be created' do
    bu = Team.create name: 'Busy Units', email: 'busy.units@localhost'
    expect(bu).to be_valid
  end

  it { should have_many(:user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:users).through(:user_roles) }

  context 'validate uniqueness of name' do
    it 'errors if not unique' do
      create :team, name: 'abc'
      t2 = build :team, name: 'abc'
      expect(t2).not_to be_valid
      expect(t2.errors[:name]).to eq ['has already been taken']
    end
  end


  describe 'scope with_user' do
    it 'lists teams with a given user' do
      t1 = create :team
      t2 = create :team
      u1 = create :user
      u2 = create :user
      u1.managing_teams << t1
      u2.managing_teams << t2
      expect(Team.with_user(u1)).to eq [t1]
    end
  end
end
