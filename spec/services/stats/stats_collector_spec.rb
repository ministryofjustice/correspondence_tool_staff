require 'rails_helper'

module Stats
  describe StatsCollector do

    let(:rows) { %w(Cats Dogs Horses Ducks) }
    let(:cols) {%w(White Brown Black) }
    let(:collector)  { StatsCollector.new(rows, cols) }

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
        }.to raise_error ArgumentError, "No such row name: 'Mice'"
      end

      it 'raises if a non-existent sub category is specified' do
        expect{
          collector.record_stats('Dogs', 'Purple')
        }.to raise_error ArgumentError, "No such column name: 'Purple'"
      end
    end


    describe '#row_names' do
      it 'returns an array of all the categories' do
        expect(collector.row_names).to eq rows.sort
      end
    end


    describe '#column_names' do
      it 'returns all the subcategories for the named category' do
        expect(collector.column_names).to eq cols
      end
    end


    describe '#value' do
      it 'returns the value for the named row and column' do
        collector.record_stats('Dogs', 'Black', 2)
        collector.record_stats('Dogs', 'Black')
        expect(collector.value('Dogs', 'Black')).to eq 3
      end
    end


    describe '#to_csv' do
      it 'returns CSV string with column header for first column' do
        collector.record_stats('Cats', 'Brown', 4)
        collector.record_stats('Dogs', 'White', 1)
        collector.record_stats('Dogs', 'Black', 2)
        expect(collector.to_csv('Animal')).to eq(
            "Animal,White,Brown,Black\n" +
            "Cats,0,4,0\n" +
            "Dogs,1,0,2\n" +
            "Ducks,0,0,0\n" +
            "Horses,0,0,0\n")
      end

      it 'returns CSV string without column header for first column' do
        collector.record_stats('Cats', 'Brown', 4)
        collector.record_stats('Dogs', 'White', 1)
        collector.record_stats('Dogs', 'Black', 2)
        expect(collector.to_csv).to eq(
            "\"\",White,Brown,Black\n" +
            "Cats,0,4,0\n" +
            "Dogs,1,0,2\n" +
            "Ducks,0,0,0\n" +
            "Horses,0,0,0\n")
      end
    end
  end
end
