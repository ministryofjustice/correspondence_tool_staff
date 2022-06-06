require 'rails_helper'


describe 'CSVGenerator' do

  class DummyCaseCSVExporter

    CSV_COLUMN_HEADINGS = [
      'test column'
    ].freeze

    def initialize(**options)
    end

    def analyse_case(kase)
      [
        kase.number
      ]
    end
  end

  describe '#to_csv' do
    it 'returns an array of arrays with default csv exporter' do
      k1_fields = ['an','array','of','text','fields','for','case 1']
      k2_fields = ['an','array','of','text','fields','for','case 2']
      kase1 = double Case::Base, to_csv: k1_fields
      kase2 = double Case::Base, to_csv: k2_fields

      generator = CSVGenerator.new([kase1, kase2], CSVExporter.new(nil))
      expected = ["#{CSVExporter::CSV_COLUMN_HEADINGS.join(',')}\n",
                  "#{k1_fields.join(',')}\n",
                  "#{k2_fields.join(',')}\n"]
      results = generator.to_a
      results[0] = results[0].delete('"')
      expect(results).to eq expected
    end

    it 'returns an array of arrays with injected case-csv exporter' do
      kase1 = double Case::Base, number: 1
      kase2 = double Case::Base, number: 2
      
      dummy_case_csv_exporter = DummyCaseCSVExporter.new()
      generator = CSVGenerator.new([kase1, kase2], dummy_case_csv_exporter)
      expected = ["#{DummyCaseCSVExporter::CSV_COLUMN_HEADINGS.join(',')}\n",
                  "1\n",
                  "2\n"]
      expect(generator.to_a).to eq expected
    end

  end

  describe '#filename' do
    it 'returns a filename based on time and action' do
      Timecop.freeze Time.local(2018, 11, 7, 13, 44, 55) do
        expect(CSVGenerator.filename('closed')).to eq('closed-cases-18-11-07-134455.csv')
      end
    end
  end
end
