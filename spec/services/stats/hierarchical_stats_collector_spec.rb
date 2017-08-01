require 'rails_helper'

module Stats

  AnimalClass = Struct.new(:name)
  AnimalName  = Struct.new(:name, :animal_class)
  AnimalBreed = Struct.new(:name, :animal_name)

  describe HierarchicalStatsCollector do
    let(:mammals)        { AnimalClass.new('Mammals') }
    let(:cats)           { AnimalName.new('Cats', mammals)}
    let(:dogs)           { AnimalName.new('Dogs', mammals)}
    let(:russian_blue)   { AnimalBreed.new('Russian Blue', cats) }
    let(:scottish_fold)  { AnimalBreed.new('Scottish Fold', cats) }
    let(:jack_russel)    { AnimalBreed.new('Jack Russel', dogs) }
    let(:newfoundlander) { AnimalBreed.new('Newfoundlander', dogs) }

    let(:rows)       { [russian_blue, scottish_fold, jack_russel, newfoundlander] }
    let(:cols)       { { white: 'White', brown: 'Brown', black: 'Black' } }
    let(:hierarchy)  { { animal_class: 'Class',
                         animal_name: 'Name',
                         breed: 'Breed' } }
    let(:collector)  { HierarchicalStatsCollector.new(rows, cols, hierarchy) }

    describe '.new' do
      it 'instantiates an empty result set' do

        expect(collector.stats).to eq(
          {
            mammals => {
              stats: { :white => 0, :brown => 0, :black => 0 },
              children: {
                cats => {
                  stats: { :white => 0, :brown => 0, :black => 0 },
                  children: {
                    russian_blue => {
                      stats: { :white => 0, :brown => 0, :black => 0 },
                    },
                    scottish_fold => {
                      stats: { :white => 0, :brown => 0, :black => 0 },
                    },
                  }
                },
                dogs => {
                  stats: { :white => 0, :brown => 0, :black => 0 },
                  children: {
                    jack_russel => {
                      stats: { :white => 0, :brown => 0, :black => 0 },
                    },
                    newfoundlander => {
                      stats: { :white => 0, :brown => 0, :black => 0 },
                    },
                  }
                }}
            }
          })
      end
    end

    describe '#column_names' do
      it 'returns all the subcategories for the named category' do
        expect(collector.column_names).to eq cols.values
      end
    end

    describe '#to_csv' do
      it 'returns CSV string with column header for first column' do
        collector.record_stats(scottish_fold, :brown, 4)
        collector.record_stats(jack_russel, :white, 1)
        collector.record_stats(newfoundlander, :black, 2)
        expect(collector.to_csv([:animal_class, :animal_name, :breed],
                                [%w{Animal Animal Animal Colour Colour Colour}]))
          .to eq(<<~EOCSV)
            Animal,Animal,Animal,Colour,Colour,Colour
            Class,Name,Breed,White,Brown,Black
            Mammals,"","",1,4,2
            Mammals,Cats,"",0,4,0
            Mammals,Cats,Russian Blue,0,0,0
            Mammals,Cats,Scottish Fold,0,4,0
            Mammals,Dogs,"",1,0,2
            Mammals,Dogs,Jack Russel,1,0,0
            Mammals,Dogs,Newfoundlander,0,0,2
          EOCSV
      end

      it 'returns CSV string without column header for first column' do
        collector.record_stats(scottish_fold, :brown, 4)
        collector.record_stats(jack_russel, :white, 1)
        collector.record_stats(newfoundlander, :black, 2)
        expect(collector.to_csv([:animal_class, :animal_name, :breed]))
          .to eq(<<~EOCSV)

            Class,Name,Breed,White,Brown,Black
            Mammals,"","",1,4,2
            Mammals,Cats,"",0,4,0
            Mammals,Cats,Russian Blue,0,0,0
            Mammals,Cats,Scottish Fold,0,4,0
            Mammals,Dogs,"",1,0,2
            Mammals,Dogs,Jack Russel,1,0,0
            Mammals,Dogs,Newfoundlander,0,0,2
          EOCSV
      end
    end
  end
end
