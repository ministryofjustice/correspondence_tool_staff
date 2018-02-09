# == Schema Information
#
# Table name: team_correspondence_type_roles
#
#  id                     :integer          not null, primary key
#  correspondence_type_id :integer
#  team_id                :integer
#  view                   :boolean          default(FALSE)
#  edit                   :boolean          default(FALSE)
#  manage                 :boolean          default(FALSE)
#  respond                :boolean          default(FALSE)
#  approve                :boolean          default(FALSE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'rails_helper'

describe TeamCorrespondenceTypeRole do

  let(:bu)  { create :business_unit }
  let(:foi) { find_or_create :foi_correspondence_type }
  let(:sar) { find_or_create :sar_correspondence_type }

  describe 'creation' do
    let(:managing_team)   { create :managing_team,
                                   correspondence_types: [sar] }
    let(:responding_team) { create :responding_team,
                                    correspondence_types: [sar] }
    let(:approving_team)  { create :approving_team,
                                   correspondence_types: [sar] }

    context 'manager team' do
      let(:new_tcr) do
        TeamCorrespondenceTypeRole.create team: managing_team,
                                          correspondence_type: foi
      end

      it 'grants "view" privilege' do
        expect(new_tcr.view).to be_truthy
      end
      it 'grants "edit" privilege' do
        expect(new_tcr.edit).to be_truthy
      end
      it 'grants "manage" privilege' do
        expect(new_tcr.manage).to be_truthy
      end
    end

    context 'responder team' do
      let(:new_tcr) do
        TeamCorrespondenceTypeRole.create team: responding_team,
                                          correspondence_type: foi
      end

      it 'grants "view" privilege' do
        expect(new_tcr.view).to be_truthy
      end
      it 'grants "respond" privilege' do
        expect(new_tcr.respond).to be_truthy
      end
    end

    context 'approver team' do
      let(:new_tcr) do
        TeamCorrespondenceTypeRole.create team: approving_team,
                                          correspondence_type: foi
      end

      it 'grants "view" privilege' do
        expect(new_tcr.view).to be_truthy
      end
      it 'grants "approve" privilege' do
        expect(new_tcr.approve).to be_truthy
      end
    end
  end

  describe 'uniqueness across correspondence_type and team ids' do
    it 'fails if a record already exists for that team/correspondence_type' do
      new_tcr = TeamCorrespondenceTypeRole.new team: bu,
                                               correspondence_type: foi,
                                               view: true,
                                               respond: true
      expect {
        new_tcr.save!
      }.to raise_error ActiveRecord::RecordNotUnique,
                       /PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint/
    end
  end

  describe '#update_roles' do
    it 'updates an existing record with the new roles' do
      tcr = bu.correspondence_type_roles.first
      tcr.update_roles(%w{ view respond approve })
      tcr.reload
      expect(tcr.view?).to be true
      expect(tcr.edit?).to be false
      expect(tcr.manage?).to be false
      expect(tcr.respond?).to be true
      expect(tcr.approve?).to be true
    end
  end
end
