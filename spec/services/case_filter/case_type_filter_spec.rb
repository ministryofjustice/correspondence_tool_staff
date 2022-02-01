require "rails_helper"

describe CaseFilter::CaseTypeFilter do

  let(:user)               { find_or_create :disclosure_specialist_bmt }

  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
                                 :sar_noff_unassigned,
                                 :std_unassigned_foi,
                                 :trig_unassigned_foi,
                                 :std_unassigned_irc,
                                 :std_unassigned_irt,
                                 :ico_foi_unassigned,
                                 :ico_sar_unassigned,
                                 :ot_ico_foi_noff_unassigned,
                                 :ot_ico_sar_noff_unassigned,
                               ])

    @offender_sar = create :offender_sar_case

    @sar_ir_timeliness = create :sar_internal_review, sar_ir_subtype: 'timeliness'
    @sar_ir_compliance = create :sar_internal_review, sar_ir_subtype: 'compliance'
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_type_filter)  { described_class.new search_query, user, Case::Base }

  describe '.available_case_types' do
    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query)      { create :search_query }
    subject    { case_type_filter.available_choices.values[0] }

    it { should include 'foi-standard'      => 'FOI - Standard' }
    it { should include 'foi-ir-compliance' => 'FOI - Internal review for compliance' }
    it { should include 'foi-ir-timeliness' => 'FOI - Internal review for timeliness' }
    it { should include 'sar-non-offender'  => 'SAR - Non-offender' }
    it { should include 'ico-appeal'        =>'ICO appeals' }
    it { should include 'overturned-ico'    =>'ICO overturned' }

    context 'for user who is assigned to a team that only handles FOIs' do
      let(:foi)             { find_or_create(:foi_correspondence_type) }
      let(:responding_team) { create(:business_unit, correspondence_types: [foi]) }
      let(:user)            { create(:user, responding_teams: [responding_team]) }
      subject    { case_type_filter.available_choices.values[0] }

      it { should include 'foi-standard' => 'FOI - Standard' }
      it { should include 'foi-ir-compliance' => 'FOI - Internal review for compliance' }
      it { should include 'foi-ir-timeliness' => 'FOI - Internal review for timeliness' }
      it { should include 'overturned-ico'    =>'ICO overturned' }
      it { should_not include 'sar-non-offender' => 'SAR - Non-offender' }
      it { should_not include 'ico-appeal' =>'ICO appeals' }
    end
  end

  describe '#applied?' do
    subject { case_type_filter }

    context 'filter_case_type and filter_sensitivity not present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'filter_case_type present' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['foi-standard'] }
      it { should be_applied }
    end

  end

  describe '#call' do

    describe 'filtering for standard FOI cases' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['foi-standard'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.trig_unassigned_foi,
                             @setup.std_unassigned_foi,
                             @setup.ico_foi_unassigned.original_case,
                             @setup.ot_ico_foi_noff_unassigned.original_case,
                           ]
      end
    end

    describe 'filtering for internal review of FOI cases for compliance' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['foi-ir-compliance'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.std_unassigned_irc,
                           ]
      end
    end

    describe 'filtering for internal review of FOI cases for timeliness' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['foi-ir-timeliness'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.std_unassigned_irt,
                           ]
      end
    end

    describe 'filtering for SAR cases' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['sar-non-offender'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.sar_noff_unassigned,
                             @setup.ico_sar_unassigned.original_case,
                             @setup.ot_ico_sar_noff_unassigned.original_case,
                             @sar_ir_timeliness.original_case,
                             @sar_ir_compliance.original_case
                           ]
      end
    end

    xdescribe 'filtering for SAR Internal Review cases' do
      let(:search_query_sar_ir_compliance) { create :search_query,
                                             filter_case_type: ['sar-ir-compliance'] }

      let(:search_query_sar_ir_timeliness) { create :search_query,
                                             filter_case_type: ['sar-ir-timeliness'] }
      
      let(:search_query_sar_ir) { create :search_query,
                                  filter_case_type: ['sar-ir-compliance', 
                                                     'sar-ir-timeliness'] }



      it 'returns SAR Internal review timeliness cases' do
        binding.pry
        results = case_type_filter.call
        expect(results).to match_array [
                             @sar_ir_timeliness
                           ]
      end
      :w

      it 'returns SAR Internal review compliance cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @sar_ir_compliance
                           ]
      end

      it 'returns both SAR Internal review compliance, and timeliness cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @sar_ir_timeliness,
                             @sar_ir_compliance
                           ]
      end
    end

    describe 'filtering for ICO cases' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['ico-appeal']}

      it 'returns ICO FOI and ICO SAR cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.ico_foi_unassigned,
                             @setup.ico_sar_unassigned,
                             @setup.ot_ico_foi_noff_unassigned.original_ico_appeal,
                             @setup.ot_ico_sar_noff_unassigned.original_ico_appeal,
                           ]
      end
    end

    describe 'filtering for Overturned ICO cases' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['overturned-ico']}

      it 'returns Overturned FOI and Overturned SAR cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.ot_ico_foi_noff_unassigned,
                             @setup.ot_ico_sar_noff_unassigned,
                           ]
      end
    end

    describe 'filtering for Offender SAR cases' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['offender-sar']}

      it 'returns Overturned FOI and Overturned SAR cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @offender_sar
                           ]
      end
    end
  end

  describe '#crumbs' do
    context 'no filters selected' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: [],
                                       filter_sensitivity: [] }

      it 'returns no crumbs' do
        expect(case_type_filter.crumbs).to be_empty
      end
    end

    context 'filtering for cases based on type' do
 
      context 'filtering for standard FOI cases' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['foi-standard'] }

        it 'returns 1 crumb' do
          expect(case_type_filter.crumbs).to have(1).item
        end

        it 'uses "FOI - Standard" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Standard'
        end

        describe 'params that will be submitted when clicking on the crumb' do
          subject { case_type_filter.crumbs[0].second }

          it { should eq 'filter_case_type' => [''],
                         'parent_id'          => search_query.id }
        end
      end

      context 'filtering for internal review of FOI cases for compliance' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['foi-ir-compliance'] }

        it 'uses "FOI - IR Compliance" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Internal review for compliance'
        end
      end

      context 'filtering for internal review of FOI cases for timeliness' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['foi-ir-timeliness'] }

        it 'uses "FOI - IR Timeliness" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Internal review for timeliness'
        end
      end

    end
  end

  describe '.process_params!' do
    it 'processes filter_case_type, sorting and removing blanks' do
      params = { filter_case_type: [
                   '',
                   'foi-standard',
                   'foi-ir-compliance',
                   'foi-ir-timeliness',
                 ] }
      described_class.process_params!(params)
      expect(params).to eq filter_case_type: [
                             'foi-ir-compliance',
                             'foi-ir-timeliness',
                             'foi-standard',
                           ]
    end

  end
end
