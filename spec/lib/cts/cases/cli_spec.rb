require "rails_helper"
require "thor"

require "cts"
require "cts/cases/cli"

RSpec.describe CTS::Cases::CLI, tag: :cli do
  let(:cli)              { described_class.new }
  let(:number_to_create) { 1 }

  let(:cli_index) { described_class.new }
  let(:cli_warehouse_all) { described_class.new }
  let(:cli_warehouse_all_size) { described_class.new }
  let(:cli_warehouse_case_id_range) { described_class.new }
  let(:cli_warehouse_case_nuber) { described_class.new }
  let(:foi_case)      { create :foi_case }
  let(:sar_case)      { create :sar_case }

  before do
    allow(CTS).to receive(:info).and_return true
    allow(cli).to receive(:tp).and_return true
    allow(cli).to receive(:options).and_return(
      {
        number: number_to_create,
        type: "Case::FOI::Standard",
        creator: User.first.id,
      },
    )
    allow(cli_index).to receive(:options).and_return(
      {
        non_indexed: true,
        size: 2,
      },
    )
    allow(cli_warehouse_all).to receive(:options).and_return(
      { scope: "all" },
    )
    allow(cli_warehouse_all_size).to receive(:options).and_return(
      { scope: "all", size: 2 },
    )
    allow(cli_warehouse_case_id_range).to receive(:options).and_return(
      { scope: "case_id_range", start: 2, end: 3 },
    )
    allow(cli_warehouse_case_nuber).to receive(:options).and_return(
      { scope: "case_number", number: "test" },
    )
    find_or_create :team_dacu
  end

  describe "create sub-command - temporarily suspended due to failures on travis" do
    it "creates a case" do
      expect(Case::Base.count).to eq 0
      find_or_create :responding_team
      cli.create("drafting")
      expect(Case::Base.count).to eq 1
    end
  end

  describe "reindex sub-command" do
    it "reindexes all cases" do
      allow(Case::Base).to receive(:update_all_indexes).and_return([])
      cli.reindex
      expect(Case::Base).to have_received(:update_all_indexes)
    end

    it "reindexes unindexed case with specific size" do
      allow(Case::Base).to receive_message_chain(:where, :limit).and_return([sar_case, foi_case]) # rubocop:disable RSpec/MessageChain
      allow(sar_case).to receive(:update_index)
      allow(foi_case).to receive(:update_index)
      expect(SearchIndexUpdaterJob).to receive(:perform_later).with(sar_case.id)
      expect(SearchIndexUpdaterJob).to receive(:perform_later).with(foi_case.id)

      cli_index.reindex
    end
  end

  describe "warehouse sub-command" do
    it "warehouses all cases" do
      allow(::Warehouse::CaseReport).to receive(:reconcile)
      cli_warehouse_all.warehouse
      expect(::Warehouse::CaseReport).to have_received(:reconcile)
    end

    it "warehouses certain amount cases specified by size option" do
      allow(::Warehouse::CaseReport).to receive(:generate)
      allow(Case::Base).to receive_message_chain(:join, :where, :limit, :in_batches).and_return([sar_case, foi_case]) # rubocop:disable RSpec/MessageChain
      cli_warehouse_all_size.warehouse
      expect(::Warehouse::CaseReport).to have_received(:generate).twice
    end

    it "warehouses certain amount cases specified by case id range" do
      allow(::Warehouse::CaseSyncJob).to receive(:perform_later).and_return(true)
      allow(Case::Base).to receive(:where).and_return([sar_case, foi_case])
      cli_warehouse_case_id_range.warehouse
      expect(::Warehouse::CaseSyncJob).to have_received(:perform_later).at_least(2).times
    end

    it "warehouses certain amount cases specified by case number" do
      allow(::Warehouse::CaseSyncJob).to receive(:perform_later).and_return(true)
      allow(Case::Base).to receive(:where).and_return([sar_case])
      cli_warehouse_case_nuber.warehouse
      expect(::Warehouse::CaseSyncJob).to have_received(:perform_later).at_least(1).times
    end
  end
end
