# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
  it { should have_many(:manager_user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:managers).through(:manager_user_roles) }
  it { should have_many(:responder_user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:responders).through(:responder_user_roles) }
  it { should have_many(:approver_user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:approvers).through(:approver_user_roles) }

  context 'validate uniqueness of name' do
    it 'errors if not unique' do
      create :team, name: 'abc'
      t2 = build :team, name: 'abc'
      expect(t2).not_to be_valid
      expect(t2.errors[:name]).to eq ['has already been taken']
    end
  end

  context 'multiple teams created' do
    let!(:managing_team)   { create :managing_team }
    let!(:responding_team) { create :responding_team }
    let!(:approving_team)  { create :approving_team }

    describe 'managing scope' do
      it 'returns only managing teams' do
        expect(Team.managing).to eq [managing_team]
      end
    end

    describe 'responding scope' do
      it 'returns only responding teams' do
        expect(Team.responding).to eq [responding_team]
      end
    end

    describe 'approving scope' do
      it 'returns only approving teams' do
        expect(Team.approving).to eq [approving_team]
      end
    end
  end

  it 'has a working factory' do
    expect(create :team).to be_valid
  end

  context 'specific team finding and querying' do

    before(:all) do
      @press_office_team =  find_or_create :team_press_office
      @dacu_disclosure_team =  find_or_create :team_dacu_disclosure
    end

    after(:all) do
      DbHousekeeping.clean
    end

    describe '.dacu_disclosure' do
      it 'finds the DACU Disclosure team' do
        expect(Team.dacu_disclosure).to eq @dacu_disclosure_team
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
        expect(Team.press_office).to eq @press_office_team
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
  end

  describe 'scope with_user' do
    it 'lists teams with a given user' do
      t1 = create :team
      t2 = create :team
      u1 = create :user
      u2 = create :user
      t1.responders << u1
      t2.responders << u2
      expect(Team.with_user(u1)).to eq [t1]
    end
  end
end
