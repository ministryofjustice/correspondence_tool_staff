require "rails_helper"
require "fileutils"
require "csv"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  module ETL
    class DummyETLClosedCases < BaseClosedCases
      def columns
        %w[number]
      end

      def heading
        "test \n"
      end

      def result_name
        "test"
      end
    end

    describe BaseClosedCases do
      let(:default_retrieval_scope) do
        Case::Base.all
      end

      before(:all) do
        7.times do
          ::Warehouse::CaseReport.generate(create(:foi_case))
        end

        @etl = DummyETLClosedCases.new(retrieval_scope: Case::Base.all)
      end

      after(:all) do
        DbHousekeeping.clean(seed: false)
      end

      describe "#extract" do
        let(:fragments_dir) { @etl.send(:folder) }

        it "returns self" do
          expect(@etl.extract).to eq @etl
        end

        it "generates the CSV header file (fragment)" do
          expect(Dir["#{fragments_dir}/00-fragment-*"].first).to be_present
        end

        it "generates 1 or more CSV files (fragments)" do
          expect(Dir["#{fragments_dir}/01-fragment-*"].first).to be_present
        end
      end

      describe "#transform" do
        it "returns self" do
          expect(@etl.transform).to eq @etl
        end
      end

      describe "#load" do
        it "sets the results_filepath on success" do
          expect(@etl.results_filepath).to be_present
        end
      end

      describe "#num_fragments" do
        it "returns the number of csv files to generate" do
          num_fragments = @etl.send(:num_fragments)

          expect(::Warehouse::CaseReport.all.size).to eq 7
          expect(num_fragments).to eq 1
        end
      end

      describe "#new_fragment" do
        it "saves a new temp file with the given data" do
          data = "My name is bob"
          file = @etl.send(:new_fragment, data)
          expect(file.size).to be 14 # bytes
        end

        it "allows multiple fragments to be concatenated" do
          files = []
          folder = @etl.send(:folder)
          data = "Baa Baa Black Sheep, Have you any wool?, Yes sir, Yes sir"

          `cd #{folder}; rm *.*`

          # Note explicit addition of new-line character
          3.times do |i|
            files << @etl.send(:new_fragment, "#{data} -> row#{i}\n")
          end

          num_files = `ls -1 #{folder} | wc -l`.to_i
          expect(files.size).to eq 3
          expect(num_files).to eq 3

          `cd #{folder}; cat *.csv > test.csv`

          rows = CSV.read("#{folder}/test.csv")
          expect(rows.size).to eq 3

          # Crude check to show each row is different
          expect(rows[0].last.end_with?("-> row0")).to be true
          expect(rows[1].last.end_with?("-> row1")).to be true
          expect(rows[2].last.end_with?("-> row2")).to be true
        end

        it "increments current fragment number" do
          data = "Twinkle Twinkle Little Star"
          @etl.instance_variable_set(:@current_fragment_num, 0)
          file0 = @etl.send(:new_fragment, data)
          file1 = @etl.send(:new_fragment, data)

          expect(File.basename(file0.path).starts_with?("00-")).to be true
          expect(File.basename(file1.path).starts_with?("01-")).to be true
        end
      end

      describe "#folder" do
        it "returns a folder path to store temp files in" do
          path = @etl.send(:folder)
          file = File.new("#{path}test-file.txt", "w")
          expect(file).to be_present
        end
      end

      describe "#heading" do
        it "returns a single line CSV" do
          header = @etl.send(:heading)
          expect(header.size).to be > 0
          expect(header).to match("test")
          expect(header.ends_with?("\n")).to be true
          expect(header.last).not_to be ","
        end
      end

      describe "#columns" do
        it "returns list of Warehouse::CaseReport field names" do
          case_report = ::Warehouse::CaseReport.new
          @etl.send(:columns).each do |field|
            expect(case_report).to respond_to field
          end
        end
      end

      describe "#filename" do
        it "is a zip file" do
          expect(@etl.send(:filename).include?(".zip")).to be true
        end
      end

      describe "#generate_header_fragment" do
        subject { @etl.send(:generate_header_fragment) }
        it { is_expected.to respond_to :each }
      end

      describe "#generate_data_fragment" do
        subject { @etl.send(:generate_data_fragments) }
        it { is_expected.to respond_to :each }
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
