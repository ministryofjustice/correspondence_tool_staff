require 'rails_helper'

describe TeamCategoryRole do

  let(:bu)          { create :business_unit }
  let(:cat_foi)     { create :category, :foi }


  describe 'uniqueness across category and team ids' do
    it 'fails if a record already exists for that team/category' do
      new_tcr = TeamCategoryRole.new_for(team: bu, category: cat_foi, roles: %w{ view respond })
      expect {
        new_tcr.save!
      }.to raise_error ActiveRecord::RecordNotUnique, /PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint/
    end
  end

  describe '.new_for' do
    it 'instantiates a new record with the correct settings' do
      tcr = TeamCategoryRole.new_for(team: bu, category: cat_foi, roles: %w{ view respond manage })
      expect(tcr.new_record?).to be true
      expect(tcr.team_id).to eq bu.id
      expect(tcr.category_id).to eq cat_foi.id
      expect(tcr.view?).to be true
      expect(tcr.edit?).to be false
      expect(tcr.manage?).to be true
      expect(tcr.respond?).to be true
      expect(tcr.approve?).to be false
    end
  end

  describe '#update_roles' do
    it 'updates an existing record with the new roles' do
      tcr = bu.category_roles.first
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
