require 'rails_helper'
require './db/seeders/search_test_data_seeder.rb'

describe SearchTestDataSeeder do

  let!(:responding_team) { create :responding_team, id: 13 }
  let!(:seeder)          { SearchTestDataSeeder.new }

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    DbHousekeeping.clean
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    DbHousekeeping.clean
    CaseClosure::MetadataSeeder.unseed!
  end

  describe '#run' do
    it 'creates 200 cases' do
      stub_s3_uploader_for_all_files!
      seeder.run
      expect(Case::Base.all.length).to eq 200
    end
  end
end
