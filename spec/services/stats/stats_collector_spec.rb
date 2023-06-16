require "rails_helper"

module Stats
  describe StatsCollector do
    let(:rows) { %w[_DOMESTIC Cats Dogs _SPACER _FARMYARD Horses Ducks] }
    let(:cols) { { white: "White", brown: "Brown", black: "Black" } }
    let(:collector) { described_class.new(rows, cols) }

    describe ".new" do
      it "instantiates an empty result set" do
        expect(collector.stats).to eq(
          {
            "_DOMESTIC" => "",
            "Cats" => { white: 0, brown: 0, black: 0 },
            "Dogs" => { white: 0, brown: 0, black: 0 },
            "_SPACER" => "",
            "_FARMYARD" => "",
            "Horses" => { white: 0, brown: 0, black: 0 },
            "Ducks" => { white: 0, brown: 0, black: 0 },
          },
        )
      end
    end

    describe "record_stats" do
      it "adds 1 to the recorded stats if no value specified" do
        collector.record_stats("Cats", :white)
        expect(collector.stats).to eq(
          {
            "_DOMESTIC" => "",
            "Cats" => { white: 1, brown: 0, black: 0 },
            "Dogs" => { white: 0, brown: 0, black: 0 },
            "_SPACER" => "",
            "_FARMYARD" => "",
            "Horses" => { white: 0, brown: 0, black: 0 },
            "Ducks" => { white: 0, brown: 0, black: 0 },
          },
        )
      end

      it "adds the value to the recorded stats if a value is specified" do
        collector.record_stats("Horses", :brown, 33)
        expect(collector.stats).to eq(
          {
            "_DOMESTIC" => "",
            "Cats" => { white: 0, brown: 0, black: 0 },
            "Dogs" => { white: 0, brown: 0, black: 0 },
            "_SPACER" => "",
            "_FARMYARD" => "",
            "Horses" => { white: 0, brown: 33, black: 0 },
            "Ducks" => { white: 0, brown: 0, black: 0 },
          },
        )
      end

      it "raises if a non-existent category is specified" do
        expect {
          collector.record_stats("Mice", :brown)
        }.to raise_error ArgumentError, "No such row name: 'Mice'"
      end

      it "raises if a non-existent column is specified" do
        expect {
          collector.record_stats("Dogs", :purple)
        }.to raise_error ArgumentError, "No such column name: ':purple'"
      end
    end

    describe "record_text" do
      it "overwrites the column with the given text" do
        collector.record_text "Dogs", :brown, "None"
        expect(collector.stats).to eq(
          {
            "_DOMESTIC" => "",
            "Cats" => {
              white: 0,
              brown: 0,
              black: 0,
            },
            "Dogs" => {
              white: 0,
              brown: "None",
              black: 0,
            },
            "_SPACER" => "",
            "_FARMYARD" => "",
            "Horses" => {
              white: 0,
              brown: 0,
              black: 0,
            },
            "Ducks" => {
              white: 0,
              brown: 0,
              black: 0,
            },
          },
        )
      end
    end

    describe "#row_names" do
      it "returns an array of all the categories" do
        expect(collector.to_csv.row_names).to eq rows
      end
    end

    describe "#column_names" do
      it "returns all the subcategories for the named category" do
        expect(collector.to_csv.column_names).to eq cols.values
      end
    end

    describe "#value" do
      it "returns the value for the named row and column" do
        collector.record_stats("Dogs", :black, 2)
        collector.record_stats("Dogs", :black)
        expect(collector.to_csv.value("Dogs", :black)).to eq 3
      end
    end

    describe "#to_csv" do
      it "returns CSV string with column header for first column" do
        collector.record_stats("Cats", :brown, 4)
        collector.record_stats("Dogs", :white, 1)
        collector.record_stats("Dogs", :black, 2)
        expect(collector.to_csv(first_column_header: "Animal")
                 .map { |x| CSV.generate_line(x) })
          .to eq(
            ["Animal,White,Brown,Black\n",
             "DOMESTIC\n",
             "Cats,0,4,0\n",
             "Dogs,1,0,2\n",
             "\"\"\n",
             "FARMYARD\n",
             "Horses,0,0,0\n",
             "Ducks,0,0,0\n"],
          )
      end

      it "returns CSV string without column header for first column" do
        collector.record_stats("Cats", :brown, 4)
        collector.record_stats("Dogs", :white, 1)
        collector.record_stats("Dogs", :black, 2)
        expect(collector.to_csv.map { |x| CSV.generate_line(x) })
          .to eq [
            "\"\",White,Brown,Black\n",
            "DOMESTIC\n",
            "Cats,0,4,0\n",
            "Dogs,1,0,2\n",
            "\"\"\n",
            "FARMYARD\n",
            "Horses,0,0,0\n",
            "Ducks,0,0,0\n",
          ]
      end
    end

    describe "#add_callback" do
      it "calls executes the specified callback method" do
        report = MockReport.new
        expect(report.stats_collector.stats).to eq({ 1 => { 1 => 0, 2 => 0 }, 2 => { 1 => 0, 2 => 0 } })
        report.run
        expect(report.stats_collector.stats).to eq({ 1 => { 1 => 999, 2 => 0 }, 2 => { 1 => 0, 2 => 0 } })
      end
    end
  end

  class MockReport
    attr_reader :stats_collector

    def initialize
      @stats_collector = StatsCollector.new([1, 2], { 1 => "col 1", 2 => "col 2" })
    end

    def run
      @stats_collector.add_callback(:before_finalise, method(:summarize))
      @stats_collector.finalise
    end

    def summarize
      @stats_collector.stats[1][1] = 999
    end
  end
end
