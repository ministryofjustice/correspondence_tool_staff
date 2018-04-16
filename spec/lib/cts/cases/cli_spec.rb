require 'rails_helper'
require 'thor'

require 'cts'
require 'cts/cases/cli'

RSpec.describe CTS::Cases::CLI do
  let(:cli)              { CTS::Cases::CLI.new }
  let(:number_to_create) { 1 }

  before do
    allow(CTS).to receive(:info).and_return true
    allow(cli).to receive(:tp).and_return true
    allow(cli).to receive(:options).and_return(
                    {
                      number: number_to_create,
                      type: 'Case::FOI::Standard',
                    }
                  )
    find_or_create :team_dacu
  end

  describe 'create sub-command' do
    it 'creates a case' do
      expect(Case::Base.count).to eq 0
      find_or_create :responding_team
      cli.create('drafting')
      expect(Case::Base.count).to eq 1
    end
  end

  describe 'reindex sub-command' do
    it 'reindexes all cases' do
      allow(Case::Base).to receive(:update_all_indexes)
      cli.reindex
      expect(Case::Base).to have_received(:update_all_indexes)
    end
  end
end
