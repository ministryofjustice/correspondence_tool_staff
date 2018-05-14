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

  let(:arel)    { Case::Base.all }
  let(:filter)  { ExemptionFilter.new(search_query, arel) }

  describe '#applied?' do
    subject { filter }

    context 'no exemption present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'exemption_ids present' do
      let(:search_query)      { create :search_query,
                                       exemption_ids: [1] }
      it { should be_applied }
    end

    context 'common_exemption_ids present' do
      let(:search_query)      { create :search_query,
                                       common_exemption_ids: [1] }
      it { should be_applied }
    end
  end

  describe '#call' do

    context 'query contains empty exemption ids' do
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
      let(:search_query) { search_query_for(['s22'], ['s22']) }
      it 'returns matching exemptions only' do
        expect(filter.call).to match_array [@kase_1, @kase_2]
      end
    end

    context 'cases with multiple specified exemption' do
      let(:search_query) { search_query_for(%w[s22 s36], ['s36']) }
      it 'returns all cases with exemptions matching any of the specified exemption ids' do
        expect(filter.call).to match_array [ @kase_2 ]
      end
    end

    context 'class of returning object' do
      let(:search_query) {  search_query_for(['s22'], ['s36']) }
      it 'returns all cases with exemptions matching any of the specified abbreviations' do
        expect(filter.call).to be_instance_of Case::Base::ActiveRecord_Relation
      end

    end
  end

  describe '#crumbs' do
    context 'query contains no exemption ids' do
      let(:search_query)    { create :search_query, search_text: 'dogs in jail' }

      it 'returns no crumbs' do
        expect(filter.crumbs).to be_empty
      end
    end

    context 'a single exemption selected' do
      let(:s22_exemption) { CaseClosure::Exemption.s22 }
      let(:search_query)  { search_query_for(['s22'], ['s22']) }

      it 'returns a crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'returns the name of the exemption as the crumb text' do
        expect(filter.crumbs[0].first)
          .to eq '(s22) - Information intended for future publication'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter.crumbs[0].second }

        it { should include 'search_text'            => "meals" }
        it { should include 'common_exemption_ids'   => [''] }
        it { should include 'filter_assigned_to_ids' => [] }
        it { should include 'filter_case_type'       => [] }
        it { should include 'exemption_ids'          => [''] }
        it { should include 'filter_sensitivity'     => [] }
        it { should include 'filter_status'          => [] }
        it { should include 'parent_id'              => search_query.id }
      end
    end

    context 'multiple exemption selected' do
      let(:s22_exemption) { CaseClosure::Exemption.s22 }
      let(:search_query)  { search_query_for(['s22', 's26'], ['s22']) }

      it 'returns a crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'returns the exemption name + 1 more as the crumb text' do
        expect(filter.crumbs[0].first)
          .to eq '(s22) - Information intended for future publication + 1 more'
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
