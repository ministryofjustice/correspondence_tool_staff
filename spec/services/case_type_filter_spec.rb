require "rails_helper"

describe CaseTypeFilter do
  before :all do
    DbHousekeeping.clean
    puts Benchmark.measure { @setup = StandardSetup.new }

    # @foi_standard_case = create :foi_case
    # @foi_trigger_case = create :foi_case, :trigger
    # @foi_irc_case = create :compliance_review
    # @foi_irt_case = create :timeliness_review
  end

  after(:all) { DbHousekeeping.clean }

  describe 'filtering for sensitivity' do
    let(:search_query)      { create :search_query,
                                     filter_case_type: ['foi-standard'] }
    let(:case_type_filter)  { CaseTypeFilter.new(search_query,
                                                 @setup.std_unassigned_foi) }

    it 'filters for trigger cases' do
      case_type_filter.call
      expect(case_type_filter.results).to eq [@setup.std_unassigned_foi]


    end
  end
end
