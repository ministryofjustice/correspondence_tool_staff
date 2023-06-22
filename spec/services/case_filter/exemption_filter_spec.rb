require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFilter::ExemptionFilter do
  let(:user)    { find_or_create :disclosure_specialist_bmt }
  let(:arel)    { Case::Base.all }
  let(:filter)  { described_class.new(search_query, user, arel) }
  let(:kase_1)  { @kase_1 }
  let(:kase_2)  { @kase_2 }

  before(:all) do
    require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

    CaseClosure::MetadataSeeder.seed!
    @kase_1 = create_closed_case_with_exemptions("s22", "s23")          # future,  security
    @kase_2 = create_closed_case_with_exemptions("s22", "s36")          # future,  prej
    @kase_3 = create_closed_case_with_exemptions("s29", "s33", "s37")   # economy, audit, royals
    @kase_4 = create :closed_case
    @kase_5 = create :closed_case, :clarification_required
    @kase_6 = create :case
    @kase_7 = create :case
  end

  after(:all) { DbHousekeeping.clean }

  describe "#applied?" do
    subject { filter }

    context "when no exemption present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when exemption_ids present" do
      let(:search_query) do
        create :search_query,
               exemption_ids: [1]
      end

      it { is_expected.to be_applied }
    end

    context "when common_exemption_ids present" do
      let(:search_query) do
        create :search_query,
               common_exemption_ids: [1]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    context "when query contains empty exemption ids" do
      let(:search_query) { create :search_query, search_text: "dogs in jail" }

      it "returns the arel untouched" do
        expect(filter.call).to eq arel
      end
    end

    context "when no cases with specified exemptions in the database" do
      let(:search_query) { search_query_for(%w[s35 s38]) }

      it "returns an empty collection" do
        expect(filter.call).to be_empty
      end
    end

    context "when cases with one specified exemption" do
      let(:search_query) { search_query_for(%w[s22], %w[s22]) }

      it "returns matching exemptions only" do
        expect(filter.call).to match_array [kase_1, kase_2]
      end
    end

    context "when cases with multiple specified exemption" do
      let(:search_query) { search_query_for(%w[s22 s36], %w[s36]) }

      it "returns all cases with exemptions matching any of the specified exemption ids" do
        expect(filter.call).to match_array [kase_2]
      end
    end

    context "when class of returning object" do
      let(:search_query) {  search_query_for(%w[s22], %w[s36]) }

      it "returns all cases with exemptions matching any of the specified abbreviations" do
        expect(filter.call.is_a?(ActiveRecord::Relation)).to be true
      end
    end
  end

  describe "#crumbs" do
    context "when query contains no exemption ids" do
      let(:search_query) { create :search_query, search_text: "dogs in jail" }

      it "returns no crumbs" do
        expect(filter.crumbs).to be_empty
      end
    end

    context "when a single exemption selected" do
      let(:s22_exemption) { CaseClosure::Exemption.s22 }
      let(:search_query)  { search_query_for(%w[s22], %w[s22]) }

      it "returns a crumb" do
        expect(filter.crumbs).to have(1).items
      end

      it "returns the name of the exemption as the crumb text" do
        expect(filter.crumbs[0].first)
          .to eq "(s22) - Information intended for future publication"
      end

      describe "params that will be submitted when clicking on the crumb" do
        it {
          expect(filter.crumbs[0].second).to eq "common_exemption_ids" => [""],
                                                 "exemption_ids" => [""],
                                                 "parent_id" => search_query.id
        }
      en
    end

    context "when multiple exemption selected" do
      let(:s22_exemption) { CaseClosure::Exemption.s22 }
      let(:search_query)  { search_query_for(%w[s22 s26], %w[s22]) }

      it "returns a crumb" do
        expect(filter.crumbs).to have(1).items
      end

      it "returns the exemption name + 1 more as the crumb text" do
        expect(filter.crumbs[0].first)
          .to eq "(s22) - Information intended for future publication + 1 more"
      end
    end
  end

  describe ".process_params!" do
    it "processes exemption_ids, sorting, removing blanks and to_i" do
      params = { exemption_ids: ["", "3", "1", "2"] }.with_indifferent_access
      described_class.process_params!(params)
      expect(params).to eq "exemption_ids" => [1, 2, 3]
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
    create :search_query, search_text: "meals", exemption_ids: ids, common_exemption_ids: common_ids
  end

  def extract_ids_from_section_numbers(section_numbers)
    if section_numbers.nil?
      []
    else
      section_numbers.map { |snum| CaseClosure::Exemption.__send__(snum).id }
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
