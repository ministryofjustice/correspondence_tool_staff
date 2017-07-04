require 'rails_helper'

module Stats
  describe StatsCollector do

    let(:cats) { %w(Cats Dogs Horses Ducks) }
    let(:subcats) {%w(White Brown Black) }
    let(:collector)  { StatsCollector.new(cats, subcats) }

    describe '.new' do
      it 'instantiates an empty result set' do
        expect(collector.stats).to eq(
          {
            'Cats' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
            'Dogs' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
            'Horses' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
            'Ducks' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
          })
      end
    end

    describe 'record_stats' do
      it 'adds 1 to the recorded stats if no value specified' do
        collector.record_stats('Cats', 'White')
        expect(collector.stats).to eq(
         {
           'Cats' => {'White' => 1, 'Brown' => 0, 'Black' => 0},
           'Dogs' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
           'Horses' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
           'Ducks' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
         })
      end

      it 'adds the value to the recorded stats if a value is specified' do
        collector.record_stats('Horses', 'Brown', 33)
        expect(collector.stats).to eq(
         {
           'Cats' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
           'Dogs' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
           'Horses' => {'White' => 0, 'Brown' => 33, 'Black' => 0},
           'Ducks' => {'White' => 0, 'Brown' => 0, 'Black' => 0},
         })
      end

      it 'raises if a non-existent category is specified' do
        expect{
          collector.record_stats('Mice', 'Brown')
        }.to raise_error ArgumentError, "No such category: 'Mice'"
      end

      it 'raises if a non-existent sub category is specified' do
        expect{
          collector.record_stats('Dogs', 'Purple')
        }.to raise_error ArgumentError, "No such sub-category: 'Purple'"
      end
    end


    describe '#categories' do
      it 'returns an array of all the categories' do
        expect(collector.categories).to eq cats.sort
      end
    end


    describe '#subcategories' do
      it 'returns all the subcategories for the named category' do
        expect(collector.subcategories).to eq subcats.sort
      end
    end


    describe '#value' do
      it 'returns the value for the named category and subcategory' do
        collector.record_stats('Dogs', 'Black', 2)
        collector.record_stats('Dogs', 'Black')
        expect(collector.value('Dogs', 'Black')).to eq 3
      end
    end
  end
end
