# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#

require 'rails_helper'

RSpec.describe Team, type: :model do
  let(:team) { create :team }

  it 'can be created' do
    bu = Team.create name: 'Busy Units', email: 'busy.units@localhost'
    expect(bu).to be_valid
  end

  it { should have_many(:user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:users).through(:user_roles) }

   describe 'code' do
     it 'should have a code of null by default' do
       expect(team.code).to be_nil
     end
   end

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

  context 'multiple teams created' do
    let!(:managing_team)   { find_or_create :managing_team }
    let!(:responding_team) { find_or_create :responding_team }
    let!(:approving_team)  { find_or_create :approving_team }

    describe 'managing scope' do
      it 'returns only managing teams' do
        expect(BusinessUnit.managing).to eq [managing_team]
      end
    end

    describe 'responding scope' do
      it 'returns only responding teams' do
        expect(BusinessUnit.responding).to eq [responding_team]
      end
    end

    describe 'approving scope' do
      it 'returns only approving teams' do
        expect(BusinessUnit.approving).to match_array [
                                    BusinessUnit.press_office,
                                    BusinessUnit.private_office,
                                    BusinessUnit.dacu_disclosure,
                                    approving_team
                                  ]
      end
    end
  end

  it 'has a working factory' do
    expect(create :team).to be_valid
  end

  context 'specific team finding and querying' do

    before(:all) do
      @press_office_team =  find_or_create :team_press_office
      @private_office_team =  find_or_create :team_private_office
      @dacu_disclosure_team =  find_or_create :team_dacu_disclosure
    end

    after(:all) do
      DbHousekeeping.clean
    end

    describe '.dacu_disclosure' do
      it 'finds the DACU Disclosure team' do
        expect(BusinessUnit.dacu_disclosure).to eq @dacu_disclosure_team
      end
    end

    describe '#dacu_disclosure?' do
      it 'returns true if dacu disclosure' do
        expect(@dacu_disclosure_team.dacu_disclosure?).to be true
      end

      it 'returns false if not dacu disclosure' do
        expect(@press_office_team.dacu_disclosure?).to be false
      end
    end

    describe '.press_office' do
      it 'finds the Press Office team' do
        expect(BusinessUnit.press_office).to eq @press_office_team
      end
    end

    describe '#press_office?' do
      it 'returns true if press office team' do
        expect(@press_office_team.press_office?).to be true
      end

      it 'returns false if not press office team' do
        expect(@dacu_disclosure_team.press_office?).to be false
      end
    end

    describe '.private_office' do
      it 'finds the Private Office team' do
        expect(BusinessUnit.private_office).to eq @private_office_team
      end
    end

    describe '#private_office?' do
      it 'returns true if private office team' do
        expect(@private_office_team.private_office?).to be true
      end

      it 'returns false if not private office team' do
        expect(@dacu_disclosure_team.private_office?).to be false
      end
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

  describe '.team_lead' do
    it 'returns the value for the team lead property' do
      team = create :team, team_lead: 'A Team Lead'
      expect(team.team_lead).to eq 'A Team Lead'
    end
  end

  describe '.team_lead=' do
    it 'creates the value for the team lead property' do
      team.team_lead = 'A New Team Lead'
      expect(team.properties.lead.first.value).to eq 'A New Team Lead'
    end

    it 'sets the value for the team lead property' do
      team.properties << TeamProperty.new(key: 'lead', value: 'A Team Lead')
      team.team_lead = 'A Newer Team Lead'
      expect(team.properties.lead.first.value).to eq 'A Newer Team Lead'
    end
  end
end
