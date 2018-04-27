# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  query            :jsonb            not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#

require 'rails_helper'

describe SearchQuery do

  describe 'tree functions' do

    before(:each) do
      @root             = create :search_query, search_text: 'root'


      @child            = create :search_query, :filter,
                                 parent_id: @root.id,
                                 filter_case_type: ['foi-standard']
      @child_2          = create :search_query, :filter,
                                 parent_id: @root.id,
                                 filter_case_type: ['foi-ir-compliance']
    end

    describe 'root' do
      it 'find the top-most ancestor' do
        expect(@child.root).to eq @root
      end
    end

    describe 'ancestors' do
      context 'a child node' do
        it 'returns an array of ancestors, root last' do
          expect(@child.ancestors).to eq( [ @root ] )
        end
      end

      context 'the root node' do
        it 'returns and empty array' do
          expect(@root.ancestors).to be_empty
        end
      end
    end

    describe '.descendents' do
      it 'returns and array of descendents, oldest child first' do
        expect(@root.descendants).to eq( [ @child, @child_2 ] )
      end
    end
  end

  describe '#update_for_click' do

    context 'user clicks for the first time' do
      let(:search_query) { create :search_query }
      let(:position)     { 3 }

      it 'records the click' do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 1
      end

      it 'updates the highest position' do
        new_highest_position = 2
        search_query.update_for_click(new_highest_position)
        expect(search_query.highest_position).to eq new_highest_position
      end
    end

    context 'user clicks on higher option' do
      let(:search_query) { create :search_query, :clicked }
      let(:position)     { 1 }

      it 'records the click' do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 2
      end

      it 'updates the highest position' do
        search_query.update_for_click(position)
        search_query.reload
        expect(search_query.highest_position).to eq position
      end
    end

    context 'user clicks on a lower position' do
      let(:search_query) { create :search_query, :clicked }
      let(:position)     { 33 }

      it 'records the click' do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 2
      end

      it 'does not update the highest position' do
        search_query.update_for_click(position)
        expect(search_query.highest_position).to eq 3
      end
    end

  end

  describe '#results' do
    let!(:case_standard)      { create :accepted_case,
                                       :indexed,
                                       subject: 'Winnie the Pooh' }
    let!(:case_trigger)       { create :accepted_case,
                                       :flagged,
                                       :indexed,
                                       subject: 'Tigger the tiger' }
    let!(:case_ir_compliance) { create :compliance_review,
                                       :indexed,
                                       subject: 'Gruffalo' }
    let(:user)    { create :manager }

    it 'returns the result of searching for search_text' do
      search_query = create :search_query,
                            user_id: user.id,
                            search_text: 'Pooh'
      expect(search_query.results).to eq [case_standard]
    end

    it 'returns the result of filtering for sensitivity' do
      search_query = create :search_query,
                            user_id: user.id,
                            search_text: 'tigger',
                            filter_sensitivity: ['trigger']
      expect(search_query.results).to eq [case_trigger]
    end

    it 'returns the result of filtering for type' do
      search_query = create :search_query,
                            user_id: user.id,
                            search_text: 'gruffalo',
                            filter_case_type: ['foi-ir-compliance']
      expect(search_query.results).to eq [case_ir_compliance]
    end
  end
end
