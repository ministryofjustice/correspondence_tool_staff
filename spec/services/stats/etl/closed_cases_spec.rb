require 'rails_helper'
require 'fileutils'
require 'csv'

module Stats
  module ETL
    describe ClosedCases do
      let(:default_retrieval_scope) {
        Case::Base.all
      }

      let(:closed_cases_etl) {
        7.times do
          ::Warehouse::CaseReport.generate(create :foi_case)
        end

        described_class.new(retrieval_scope: default_retrieval_scope)
      }

      describe '#initialize' do
        it 'generates a single zip file from multiple csv files' do
          fragments_dir = closed_cases_etl.send(:folder)

          expect(Dir["#{fragments_dir}/closed-cases.csv"].first).to be_present
          expect(Dir["#{fragments_dir}/closed-cases.zip"].first).to be_present
        end
      end

      describe '#extract' do
        let(:etl) {
          described_class.new(retrieval_scope: default_retrieval_scope)
        }
        
        let(:fragments_dir) { etl.send(:folder) }

        it 'returns self' do
          expect(etl.extract).to eq etl
        end

        it 'generates the CSV header file (fragment)' do
          expect(Dir["#{fragments_dir}/fragment_00_header*"].first).to be_present
        end

        it 'generates 1 or more CSV files (fragments)' do
          expect(Dir["#{fragments_dir}/fragment_01*"].first).to be_present
        end
      end

      describe '#transform' do
        it 'returns self' do
          etl = described_class.new(retrieval_scope: default_retrieval_scope)
          expect(etl.transform).to eq etl
        end
      end

      describe '#load' do
        it 'returns self' do
          etl = described_class.new(retrieval_scope: default_retrieval_scope)
          expect(etl.load).to eq etl
        end

        it 'sets the results_filepath on success' do
          expect(closed_cases_etl.results_filepath).to be_present
        end
      end

      describe '#num_fragments' do
        it 'returns the number of csv files to generate' do
          num_fragments = closed_cases_etl.send(:num_fragments)

          expect(::Warehouse::CaseReport.all.size).to eq 7
          expect(num_fragments).to eq 1
        end
      end

      describe '#new_fragment' do
        it 'saves a new temp file with the given data' do
          filename = 'useless-file'
          data = 'My name is bob'
          file = closed_cases_etl.send(:new_fragment, filename, data)
          expect(file.size).to be 15 # 14 chars + new line char
        end

        it 'allows multiple fragments to be concatenated with new line' do
          files = []
          folder = closed_cases_etl.send(:folder)
          data = 'Baa Baa Black Sheep, Have you any wool?, Yes sir, Yes sir'

          3.times do |i|
            filename = "csv-fragment-#{i}.csv"
            files << closed_cases_etl.send(:new_fragment, filename, "#{data}-row#{i}")
          end

          `cd #{folder}; cat csv-fragment-* > test.csv`

          rows = CSV.read("#{folder}/test.csv")
          expect(rows.size).to eq 3

          # Crude check to show each row is different
          expect(rows[0].last.end_with? '-row0').to be true
          expect(rows[1].last.end_with? '-row1').to be true
          expect(rows[2].last.end_with? '-row2').to be true
        end
      end

      describe '#folder' do
        it 'returns a folder path to store temp files in' do
          path = closed_cases_etl.send(:folder)
          file = File.new(path + 'test-file.txt', 'w')
          expect(file).to be_present
        end
      end

      describe '#heading' do
        it 'returns a single line CSV' do
          header = closed_cases_etl.send(:heading)
          expect(header.size).to be > 0
          expect(header).to match(/([a-zA-Z0-9,\s])+/)
          expect(header.include? "\n").to be false
          expect(header.last).not_to be ','
        end
      end

      describe '#columns' do
        it 'returns list of Warehouse::CaseReport field names' do
          case_report = ::Warehouse::CaseReport.new
          closed_cases_etl.send(:columns).each do |field|
            expect(case_report).to respond_to field
          end
        end
      end

      describe '#filename' do
        it 'should be a zip file' do
          expect(closed_cases_etl.send(:filename).include?('.zip')).to be true
        end
      end
    end
  end
end
