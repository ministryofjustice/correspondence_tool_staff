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
#  code       :string
#  deleted_at :datetime
#

require 'rails_helper'

RSpec.describe BusinessUnit, type: :model do
  let(:foi)   { Category.foi }
  let(:sar)   { Category.sar }


  it 'can be created' do
    bu = BusinessUnit.create name: 'Busy Units',
                             email: 'busy.units@localhost',
                             parent_id: 1,
                             role: 'responder',
                             category_ids: [foi.id]
    expect(bu).to be_valid
  end

  it { should validate_presence_of(:parent_id) }

  it { should belong_to(:directorate).with_foreign_key(:parent_id) }

  it { should have_one(:business_group).through(:directorate)}

  it { should have_many(:user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:users).through(:user_roles) }
  it { should have_many(:manager_user_roles)
                .class_name('TeamsUsersRole')
                .with_foreign_key('team_id') }
  it { should have_many(:managers).through(:manager_user_roles) }
  it { should have_many(:responder_user_roles)
                 .class_name('TeamsUsersRole')
                 .with_foreign_key('team_id') }
  it { should have_many(:responders).through(:responder_user_roles) }
  it { should have_many(:approver_user_roles)
                .class_name('TeamsUsersRole')
                .with_foreign_key('team_id') }
  it { should have_many(:approvers).through(:approver_user_roles) }

  context 'multiple teams created' do
    let!(:managing_team)   { find_or_create :managing_team }
    let!(:responding_team) { find_or_create :responding_team }
    let!(:approving_team)  { find_or_create :approving_team }

    describe 'managing scope' do
      it 'returns only managing teams' do
        expect(BusinessUnit.managing).to match_array [
                                           managing_team
                                         ]
      end
    end

    describe 'responding scope' do
      it 'returns only responding teams' do
        # ap BusinessUnit.pluck(:id, :name, :role)
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
    expect(create :business_unit).to be_valid
  end

  context 'specific team finding and querying' do

    before(:all) do
      @press_office_team =  find_or_create :team_press_office
      @private_office_team =  find_or_create :team_private_office
      @dacu_disclosure_team =  find_or_create :team_dacu_disclosure
      @dacu_bmt_team = find_or_create :team_dacu
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
    end

    describe '.dacu_bmt' do
      it 'finds the DACU BMT team' do
        expect(BusinessUnit.dacu_bmt).to eq @dacu_bmt_team
      end
    end

    describe '#dacu_bmt?' do
      it 'returns true if dacu bmt' do
        expect(@dacu_bmt_team.dacu_bmt?).to be true
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

  context 'team category roles' do

    let(:foi_cat)   { create :category, :foi }
    let(:sar_cat)   { create :catetory, :sar }
    let(:bu)        { create :business_unit }

    describe 'set team category roles' do
      it 'creates a new one if not already in the database' do
        dir = create :directorate
        bu = BusinessUnit.create(name: 'bu1', parent: dir, role: 'manager')
        bu.set_category_roles(category_abbreviation: 'foi', roles: %w{ view manage edit })
        expect(bu.category_roles.size).to eq 1
        expect(bu.category_roles.first).to match_tcr_attrs(:foi, :view, :manage, :edit)
      end
    end
  end


  describe '.responding_for_category' do
    before(:each) do
      @bu_foi_sar = create :business_unit, category_ids: [foi.id, sar.id]
      @bu_foi = create :business_unit, category_ids: [foi.id]
      @bu_sar = create :business_unit, category_ids: [sar.id]
    end

    it 'only returns business units with reponding roles for the FOIs' do
      expect(BusinessUnit.responding_for_category(Category.foi)).to match_array [ @bu_foi_sar, @bu_foi ]
    end

    it 'only returns business units with reponding roles for the SARs' do
      expect(BusinessUnit.responding_for_category(Category.sar)).to match_array [ @bu_foi_sar, @bu_sar ]
    end
  end

  describe '#categories' do
    before(:each) do
      @pq = create :category, name: 'Parliamentary Qustions', abbreviation: 'PQ'
    end

    it 'returns an array of Category objects' do
      bu = create :business_unit, category_ids: [sar.id, foi.id]
      create :team_category_role, :responder, team_id: bu.id, category_id: @pq.id
      expect(bu.reload.categories.map(&:abbreviation)).to match_array ['SAR', 'FOI', 'PQ']
    end
  end

  describe '#category_ids' do
    it 'returns an array of category ids' do
     @bu = create :business_unit, category_ids: [sar.id, foi.id]
    end
  end


  describe 'category_ids=' do
    let(:dir)     { create :directorate }
    let(:foi)     { find_or_create :category, :foi }
    let(:sar)     { find_or_create :category, :sar }
    let(:gq)      { find_or_create :category, :gq }

    it 'adds new team category role records' do
      bu = BusinessUnit.create(name: 'bu1', parent: dir, role: 'manager')
      expect(bu.category_roles).to be_empty
      bu.category_ids = [ foi.id, sar.id ]
      expect(bu.category_roles.size).to eq 2
      foi_tcr = bu.category_roles.detect{ |r| r.category_id == foi.id }
      sar_tcr = bu.category_roles.detect{ |r| r.category_id == sar.id }
      expect(foi_tcr).to match_tcr_attrs(:foi, :view, :edit, :manage)
      expect(sar_tcr).to match_tcr_attrs(:sar, :view, :edit, :manage)
    end

    it 'deletes unused and adds new team categories' do
      bu = create :business_unit, category_ids: [foi.id, sar.id]
      expect(bu.categories.map(&:abbreviation)).to match_array %w{ FOI SAR }
      bu.category_ids = [ sar.id, gq.id ]
      expect(bu.reload.categories.map(&:abbreviation)).to match_array %w{ SAR GQ }
    end
  end


end
