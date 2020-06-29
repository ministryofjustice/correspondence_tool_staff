require 'rails_helper'
require 'thor'

require 'cts'
require 'cts/cases/cli'

RSpec.describe CTS::Cases::CLI, tag: :cli do
  let(:cli)              { CTS::Cases::CLI.new }
  let(:number_to_create) { 1 }

  let(:cli_index) { CTS::Cases::CLI.new }
  let(:cli_warehouse) { CTS::Cases::CLI.new }
  let(:foi_case)      { create :foi_case }
  let(:sar_case)      { create :sar_case }

  before do
    allow(CTS).to receive(:info).and_return true
    allow(cli).to receive(:tp).and_return true
    allow(cli).to receive(:options).and_return(
                    {
                      number: number_to_create,
                      type: 'Case::FOI::Standard',
                      creator: User.first.id,
                    }
                  )
    allow(cli_index).to receive(:options).and_return(
      {
        non_indexed: true,
        size: 2
      }
    )
    allow(cli_warehouse).to receive(:options).and_return(
      { size: 2 }
    )
  find_or_create :team_dacu
  end


  describe 'create sub-command - temporarily suspended due to failures on travis' do
    it 'creates a case' do
      expect(Case::Base.count).to eq 0
      find_or_create :responding_team
      cli.create('drafting')
      expect(Case::Base.count).to eq 1
    end
  end

  describe 'reindex sub-command' do
    it 'reindexes all cases' do
      allow(Case::Base).to receive(:update_all_indexes).and_return([])
      cli.reindex
      expect(Case::Base).to have_received(:update_all_indexes)
    end

    it 'reindexes unindexed case with specific size' do
      allow(Case::Base).to receive_message_chain(:where, :limit).and_return([sar_case, foi_case])
      allow(sar_case).to receive(:update_index)
      allow(foi_case).to receive(:update_index)
      cli_index.reindex
      expect(sar_case).to have_received(:update_index)
      expect(foi_case).to have_received(:update_index)
    end

  end

  describe 'warehouse sub-command' do
    it 'warehouses all cases' do
      allow(::Warehouse::CaseReport).to receive(:reconcile)
      cli.warehouse
      expect(::Warehouse::CaseReport).to have_received(:reconcile)
    end

    it 'warehouses certain amount cases specified by size option' do
      allow(::Warehouse::CaseReport).to receive(:generate)
      allow(Case::Base).to receive_message_chain(:join, :where, :limit, :in_batches).and_return([sar_case, foi_case])
      cli_warehouse.warehouse
      expect(::Warehouse::CaseReport).to have_received(:generate).twice
    end
  end
end
