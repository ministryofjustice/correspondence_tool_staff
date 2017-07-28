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

  it { should validate_uniqueness_of(:name) }
  it { should have_many(:user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:users).through(:user_roles) }

  describe 'email' do
    it 'should consider team emails to be case-insensitive' do
      team = Team.create name: 'test', email: 'TEST@localhost'
      expect(Team.find_by(email: 'test@localhost')).to eq team
    end
  end

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

  describe '#can_allocate?' do
    before(:each) do
      @team = create :team
      @foi = create :category, :foi
      @gq = create :category, :gq
      create :team_property, :can_allocate_gq, team_id: @team.id
    end

    it 'returns false if there is no team property with key can_allocate for specified category' do
      expect(@team.can_allocate?(@foi)).to be false
    end

    it 'returns true if there is a team property key can_allocate for specified category' do
      expect(@team.can_allocate?(@gq)).to be true
    end
  end

  describe '#enable_allocation' do

    let(:team)  { create :team }
    let(:foi)   { create :category, :foi }

    it 'creates a team property record' do
      expect(TeamProperty.where(key: 'can_allocate', value: foi.abbreviation).size).to eq 0
      team.enable_allocation(foi)
      expect(TeamProperty.where(key: 'can_allocate', value: foi.abbreviation).size).to eq 1
    end

    it 'does not duplicate the team property record if one already exists' do
      expect(TeamProperty.where(key: 'can_allocate', value: foi.abbreviation).size).to eq 0
      team.enable_allocation(foi)
      team.enable_allocation(foi)
      expect(TeamProperty.where(key: 'can_allocate', value: foi.abbreviation).size).to eq 1
    end
  end

  describe '#disable_allocation' do
    before(:each) do
      @team = create :team
      @foi = create :category, :foi
      create :team_property, :can_allocate_foi, team_id: @team.id
    end

    it 'deletes the team property' do
      expect(TeamProperty.where(key: 'can_allocate', value: @foi.abbreviation).size).to eq 1
      @team.disable_allocation(@foi)
      expect(TeamProperty.where(key: 'can_allocate', value: @foi.abbreviation).size).to eq 0
    end

    it 'doesnt fail if called twice' do
      expect(TeamProperty.where(key: 'can_allocate', value: @foi.abbreviation).size).to eq 1
      @team.disable_allocation(@foi)
      @team.disable_allocation(@foi)
      expect(TeamProperty.where(key: 'can_allocate', value: @foi.abbreviation).size).to eq 0
    end
  end

  describe '.allocatable' do
    it 'returns a collection of teams that have the can_allocate property set for the category' do
      foi = create :category, :foi
      gq = create :category, :gq
      t1 = create :team
      t2 = create :team
      t3 = create :team
      t4 = create :team
      [t1, t2, t4].each { |t| t.enable_allocation(foi) }
      [t3, t4].each { |t| t.enable_allocation(gq) }
      expect(Team.allocatable(foi)).to match_array [t1, t2, t4]
      expect(Team.allocatable(gq)).to match_array [t3, t4]
    end
  end
end
