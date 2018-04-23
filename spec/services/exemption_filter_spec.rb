require 'rails_helper'

describe Case::Base do

  before(:all) do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

    CaseClosure::MetadataSeeder.seed!
    @kase_1 = create_closed_case_with_exemptions('s22', 's23')          # future,  security
    @kase_2 = create_closed_case_with_exemptions('s22', 's36')          # future,  prej
    @kase_3 = create_closed_case_with_exemptions('s29', 's33', 's37')   # economy, audit, royals
    @kase_4 = create :closed_case
    @kase_5 = create :closed_case, :clarification_required
    @kase_6 = create :case
    @kase_7 = create :case
  end

  after(:all) { DbHousekeeping.clean }

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { ExemptionFilter.new(search_query, arel) }

    context 'query contains empty exemption ids and common exemption ids' do
      let(:search_query)    { create :search_query, search_text: 'dogs in jail' }
      it 'returns the arel untouched' do
        expect(filter.call).to eq arel
      end

    end

    context 'no cases with specified exemptions in the database' do
      let(:search_query) { search_query_for(%w[s35 s38]) }
      it 'returns an empty collection' do
        expect(filter.call).to be_empty
      end
    end

    context 'cases with one specified exemption' do
      let(:search_query) { search_query_for([], %w[s22]) }
      it 'returns matching exemptions only' do
        expect(filter.call).to match_array [@kase_1, @kase_2]
      end
    end

    context 'cases with multiple specified exemption' do
      let(:search_query) { search_query_for(%w[s22], %w[s36]) }
      it 'returns all cases with exemptions matching any of the specified exemption ids' do
        expect(filter.call).to match_array [ @kase_2 ]
      end
    end

    context 'class of returning object' do
      let(:search_query) {  search_query_for(%w[s22], %w[s36]) }
      it 'returns all cases with exemptions matching any of the specified abbreviations' do
        expect(filter.call).to be_instance_of Case::Base::ActiveRecord_Relation
      end

    end
  end

  private

  def create_closed_case_with_exemptions(*args)
    kase = create :closed_case
    args.each do |snn|
      kase.exemptions << CaseClosure::Exemption.__send__(snn)
    end
    kase
  end

  def search_query_for(section_numbers, common_section_numbers = nil)
    ids = extract_ids_from_section_numbers(section_numbers)
    common_ids = extract_ids_from_section_numbers(common_section_numbers)
    create :search_query, search_text: 'meals', exemption_ids: ids, common_exemption_ids: common_ids
  end

  def extract_ids_from_section_numbers(section_numbers)
    if section_numbers.nil?
      []
    else
      section_numbers.map { |snum| CaseClosure::Exemption.__send__(snum).id }
    end
  end
end
