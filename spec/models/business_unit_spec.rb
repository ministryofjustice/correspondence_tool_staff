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
  let(:foi)   { CorrespondenceType.foi }
  let(:sar)   { CorrespondenceType.sar }


  it 'can be created' do
    bu = BusinessUnit.create name: 'Busy Units',
                             email: 'busy.units@localhost',
                             parent_id: 1,
                             role: 'responder',
                             correspondence_type_ids: [foi.id]
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


  context 'cases scope' do
    before(:all) do
      @team_1 = create :responding_team
      @team_2 = create :responding_team
      
      @unassigned_case                  = create :case, name: 'unassigned'
      @t1_assigned_case                 = create :assigned_case, responding_team: @team_1, name: 't1-assigned'
      @t1_accepted_case                 = create :accepted_case, responding_team: @team_1, name: 't1-accepted'
      @t1_rejected_case                 = create :rejected_case, responding_team: @team_1, name: 't1-rejected'
      @t1_pending_dacu_clearance_case   = create :pending_dacu_clearance_case, responding_team: @team_1, name: 't1-pending-dacu'
      @t1_responded_case                = create :responded_case, responding_team: @team_1, name: 't1-responded'
      @t1_closed_case                   = create :closed_case, responding_team: @team_1, name: 't1-closed'

      @t2_assigned_case                 = create :assigned_case, responding_team: @team_2, name: 't2-assigned'
      @t2_accepted_case                 = create :accepted_case, responding_team: @team_2, name: 't2-accepted'
      @t2_rejected_case                 = create :rejected_case, responding_team: @team_2, name: 't2-rejected'
      @t2_pending_dacu_clearance_case   = create :pending_dacu_clearance_case, responding_team: @team_2, name: 't2-pending-dacu'
      @t2_responded_case                = create :responded_case, responding_team: @team_2, name: 't2-responded'
      @t2_closed_case                   = create :closed_case, responding_team: @team_2, name: 't2-closed'
    end

    after(:all) { DbHousekeeping.clean }

    describe 'scope cases' do
      it 'returns all cases allocated to the team including rejected and closed' do
        expect(@team_1.cases).to match_array([
            @t1_assigned_case,
            @t1_accepted_case,
            @t1_rejected_case,
            @t1_pending_dacu_clearance_case,
            @t1_responded_case,
            @t1_closed_case])
      end
    end

    describe 'scope pending_accepted_cases' do
      it 'does not return responded or closed cases' do
        expect(@team_1.open_cases).to match_array([
           @t1_assigned_case,
           @t1_accepted_case,
           @t1_pending_dacu_clearance_case])
      end
    end
  end

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

  describe '.responding_for_correspondence_type' do
    before(:each) do
      @bu_foi_sar = create :business_unit, correspondence_type_ids: [foi.id, sar.id]
      @bu_foi = create :business_unit, correspondence_type_ids: [foi.id]
      @bu_sar = create :business_unit, correspondence_type_ids: [sar.id]
    end

    it 'only returns business units with reponding roles for the FOIs' do
      expect(BusinessUnit.responding_for_correspondence_type(CorrespondenceType.foi)).to match_array [ @bu_foi_sar, @bu_foi ]
    end

    it 'only returns business units with reponding roles for the SARs' do
      expect(BusinessUnit.responding_for_correspondence_type(CorrespondenceType.sar)).to match_array [ @bu_foi_sar, @bu_sar ]
    end
  end

  describe '#correspondence_types' do
    let(:foi) { find_or_create :foi_correspondence_type }
    let(:sar) { find_or_create :sar_correspondence_type }
    let(:dir)  { create :directorate}

    it { should have_many(:correspondence_types).through(:correspondence_type_roles) }

    it 'removes existing correspondence type roles when assigning' do
      bu = BusinessUnit.create name: 'correspondence_type test',
                               role: 'manager',
                               parent: dir,
                               correspondence_types: [foi]
      expect(bu.correspondence_types).to eq [foi]
      bu.correspondence_types = [sar]
      bu.reload
      expect(bu.correspondence_types).to eq [sar]
    end
  end

  describe '#correspondence_type_ids' do
    it 'returns an array of correspondence_type ids' do
      @bu = create :business_unit, correspondence_type_ids: [sar.id, foi.id]
      expect(@bu.correspondence_type_ids).to match_array([sar.id, foi.id])
    end
  end


  describe '#correspondence_type_ids=' do
    let(:dir) { create :directorate }
    let(:foi) { find_or_create :foi_correspondence_type }
    let(:sar) { find_or_create :sar_correspondence_type }
    let(:gq)  { find_or_create :gq_correspondence_type }

    it 'adds new team correspondence_type role records' do
      bu = BusinessUnit.new(name: 'bu1', parent: dir, role: 'manager')
      expect(bu.correspondence_type_roles).to be_empty
      bu.correspondence_type_ids = [ foi.id, sar.id ]
      bu.save
      expect(bu.correspondence_type_roles.size).to eq 2
      foi_tcr = bu.correspondence_type_roles.detect{ |r| r.correspondence_type_id == foi.id }
      sar_tcr = bu.correspondence_type_roles.detect{ |r| r.correspondence_type_id == sar.id }
      expect(foi_tcr).to match_tcr_attrs(:foi, :view, :edit, :manage)
      expect(sar_tcr).to match_tcr_attrs(:sar, :view, :edit, :manage)
    end

    it 'deletes unused and adds new team correpondence_types' do
      bu = create :business_unit, correspondence_types: [foi, sar]
      expect(bu.correspondence_types.map(&:abbreviation))
        .to match_array %w{ FOI SAR }
      bu.correspondence_type_ids = [ sar.id, gq.id ]
      expect(bu.reload.correspondence_types.map(&:abbreviation))
        .to match_array %w{ SAR GQ }
    end
  end


end
