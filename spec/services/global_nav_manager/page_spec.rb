require 'rails_helper'


describe GlobalNavManager::Page do
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:disclosure_bmt_user)   { create :disclosure_bmt_user }
  let(:responder)             { create :responder }
  let(:request)               { instance_double ActionDispatch::Request,
                                                path: '/cases/open',
                                                fullpath: '/cases/open',
                                                query_parameters: {} }

  let(:settings) do
    YAML.load(ERB.new(<<~EOY).result)
      pages:
        incoming_cases:
          path: '/incoming'
          visibility:
            'DISCLOSURE':
              filter: incoming_for_disclosure,
        open_cases:
          path: '/opened'
          filter: opened
          tabs:
            in_time:
              filter: in_time
            late:
              filter: late
        closed_cases:
          path: '/closed'
          filter: closed
        stats_page:
          path: '/stats'
          visibility:
            - manager
     EOY
  end
  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end

  let(:global_nav)  { instance_double GlobalNavManager,
                                      user: responder,
                                      request: request }
  let(:incoming_cases_page) { described_class.new(
                                :incoming_cases,
                                global_nav,
                                config.pages.incoming_cases
                              ) }
  let(:open_cases_page) { described_class.new(
                            :open_cases,
                            global_nav,
                            config.pages.open_cases
                          ) }
  let(:closed_cases_page) { described_class.new(
                              :closed_cases,
                              global_nav,
                              config.pages.closed_cases
                            ) }
  let(:stats_page) { described_class.new(
                       :stats,
                       global_nav,
                       config.pages.stats_page
                     ) }
  let(:in_time_tab) { instance_double(GlobalNavManager::Tab,
                                      fullpath: :in_time_fullpath,
                                      visible?: true) }
                                      # url: :in_time_tab_url) }
  let(:late_tab)    { instance_double(GlobalNavManager::Tab,
                                      fullpath: :late_fullpath,
                                      visible?: true) }

  before do
    allow(GlobalNavManager::Tab).to receive(:new)
                                      .with(:in_time, any_args())
                                      .and_return(in_time_tab)
    allow(GlobalNavManager::Tab).to receive(:new)
                                      .with(:late, any_args())
                                      .and_return(late_tab)
    allow(CaseFinderService).to receive(:new)
                                  .and_return(instance_spy(CaseFinderService))
  end

  context 'initialization' do
    describe '#tabs' do
      it 'creates tab objects for the list provided' do
        expect(open_cases_page.tabs).to eq [in_time_tab, late_tab]
      end
    end

    it 'uses user team(s) to determine visibility' do
      expect(disclosure_specialist).not_to be_a_manager
      expect(disclosure_specialist.teams.pluck :code).to include 'DISCLOSURE'
      allow(global_nav).to receive(:user).and_return(disclosure_specialist)

      expect(incoming_cases_page.visible?).to eq true
      expect(open_cases_page.visible?).to eq true
      expect(closed_cases_page.visible?).to eq true
      expect(stats_page.visible?).to eq false
    end

    it 'uses user role(s) to determine visibility' do
      expect(disclosure_bmt_user).to be_a_manager
      expect(disclosure_bmt_user.teams.pluck :code).not_to include 'DISCLOSURE'
      allow(global_nav).to receive(:user).and_return(disclosure_bmt_user)

      expect(incoming_cases_page.visible?).to eq false
      expect(open_cases_page.visible?).to eq true
      expect(closed_cases_page.visible?).to eq true
      expect(stats_page.visible?).to eq true
    end

    it 'sets the visibility depending on settings' do
      expect(responder).not_to be_a_manager
      expect(responder.teams.pluck :code).not_to include 'DISCLOSURE'
      allow(global_nav).to receive(:user).and_return(responder)
      expect(incoming_cases_page.visible?).to be false
      expect(open_cases_page.visible?).to be true
      expect(closed_cases_page.visible?).to eq true
      expect(stats_page.visible?).to eq false
    end
  end

  describe '#filters' do
    it 'returns the filters' do
      expect(open_cases_page.filters).to eq ['opened']
    end
  end

  describe '#path' do
    it 'returns the path' do
      expect(open_cases_page.path).to eq '/opened'
    end
  end

  describe '#fullpath' do
    context 'on a page with no tabs' do
      it "returns the page's path" do
        expect(closed_cases_page.fullpath).to eq '/closed'
      end
    end

    context 'on a page with tabs' do
      it 'returns the path of the first tab' do
        expect(open_cases_page.fullpath).to eq :in_time_fullpath
      end
    end
  end

  let(:finder) { instance_double CaseFinderService }

  describe '#finder' do
    it 'returns a CaseFinderService object' do
      cfs = instance_double(CaseFinderService)
      allow(CaseFinderService).to receive(:new).and_return(cfs)
      result = open_cases_page.finder
      expect(result).to be cfs
      expect(CaseFinderService).to have_received(:new)
                                     .with(responder,
                                           ['opened'],
                                           request.query_parameters)

    end
  end

  describe '#cases' do
    it 'returns the cases from the finder' do
      finder = instance_double CaseFinderService,
                               cases: double('Case::ActiveRecord_Relation')
      allow(open_cases_page).to receive(:finder).and_return(finder)
      expect(open_cases_page.cases).to eq finder.cases
    end
  end

  describe '#matches_path?' do
    it '#matches_path? returns true if the paths match' do
      expect(open_cases_page.matches_path? :in_time_fullpath).to be true
    end
  end
end
