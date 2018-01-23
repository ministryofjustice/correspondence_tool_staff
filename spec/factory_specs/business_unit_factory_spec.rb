require 'rails_helper'

describe 'Business Unit factories' do

  let(:sar)   { Category.sar }

  describe ':business_unit' do
    context 'without params' do
      it 'creates responding team with responding team category role for FOI' do
        bu = create :business_unit
        expect(bu.role).to eq 'responder'
        expect(bu.category_roles.size).to eq 2
        tcr = bu.category_roles.first
        expect(tcr).to match_tcr_attrs(:foi, :view, :respond)
      end
    end

    context 'with categories param' do
      it 'creates a responding team with category role for SAR' do
        bu = create :business_unit, category_ids: [sar.id]
        expect(bu.role).to eq 'responder'
        expect(bu.category_roles.size).to eq 1
        tcr = bu.category_roles.first
        expect(tcr).to match_tcr_attrs(:sar, :view, :respond)
      end
    end
  end

  describe 'managing_team' do
    context 'no params' do
      it 'creates a managing team with correct team category roles' do
        bu = create :managing_team
        expect(bu.role).to eq 'manager'
        expect(bu.category_roles.first).to match_tcr_attrs(:foi, :view, :edit, :manage)
      end
    end

    context 'setting category param' do
      it 'creates a managing team with correct team category roles' do
        bu = create :managing_team, category_ids: [sar.id]
        expect(bu.role).to eq 'manager'
        expect(bu.category_roles.first).to match_tcr_attrs(:sar, :view, :edit, :manage)
      end
    end
  end

  describe 'responding_team' do
    context 'no params' do
      it 'creates a responding team with correct team category roles for both FOI and SAR' do
        bu = create :responding_team

        expect(bu.role).to eq 'responder'
        expect(bu.category_roles.size).to eq 2
        foi_tcr = bu.category_roles.detect{ |r| r.category_id == Category.foi.id }
        expect(foi_tcr).to match_tcr_attrs(:foi, :view, :respond)
        sar_tcr = bu.category_roles.detect{ |r| r.category_id == Category.sar.id }
        expect(sar_tcr).to match_tcr_attrs(:sar, :view, :respond)
      end
    end
  end

end
