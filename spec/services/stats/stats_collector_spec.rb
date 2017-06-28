require 'rails_helper'

module Stats
  describe StatsCollector do

    let(:collector)  { StatsCollector.new }

    describe '#record_stats' do
      it 'creates a category and sub category if one doesnt exist' do
        collector.record_stats('abc', 'def')
        expect(collector.stats).to eq( { 'abc' => { 'def' => 1 }} )
      end

      it 'creates an additional subcategory if unique within the category' do
        collector.record_stats('abc', 'def')
        collector.record_stats('abc', 'ghi', 3)
        expect(collector.stats).to eq( { 'abc' => { 'def' => 1, 'ghi' => 3 }} )
      end
    end

    context 'getter methods' do
      before(:each) do
        collector.record_stats('abc', 'def')
        collector.record_stats('abc', 'ghi', 3)
        collector.record_stats('xyz', 'aaa')
        collector.record_stats('stu', 'ghi', 3)
      end

      describe '#categories' do
        it 'returns an array of all the categories' do
          expect(collector.categories).to eq %w( abc stu xyz )
          expect(collector.categories).to eq %w( abc stu xyz )
        end
      end


      describe '#subcategories_for' do
        it 'returns all the subcategories for the named category' do
          expect(collector.subcategories_for('abc')).to eq %w( def ghi )
        end
      end


      describe '#value' do
        it 'returns the value for the named category and subcategory' do
          expect(collector.value('abc', 'ghi')).to eq 3
        end
      end

      describe '#all_subcategories' do
        it 'returns all the sub categories' do
          expect(collector.all_subcategories).to eq %w( aaa def ghi )
        end
      end
    end
  end
end
