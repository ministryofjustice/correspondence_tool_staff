require 'rails_helper'

describe GlobalNavManager::Page do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:disclosure_bmt_user)   { find_or_create :disclosure_bmt_user }
  let(:disclosure_specialist_bmt) { find_or_create :disclosure_specialist_bmt }
  let(:press_officer)         { find_or_create :press_officer }
  let(:responder)             { find_or_create :foi_responder }
  let(:request)               { instance_double ActionDispatch::Request,
                                                path: '/cases/open',
                                                fullpath: '/cases/open',
                                                query_parameters: {} }

  let(:settings) do
    YAML.load(ERB.new(<<~EOY).result)
      pages:
        incoming_cases:
          path: '/incoming'
          visibility: approver
          scope:
            'PRESS-OFFICE': incoming_for_press_office
        open_cases:
          path: '/opened'
          scope:
            manager: opened
            responder: opened
            approver: flagged
          tabs:
            in_time:
              scope: in_time
            late:
              scope: late
        closed_cases:
          path: '/closed'
          scope: closed
        stats_page:
          path: '/stats'
          visibility: manager
     EOY
  end
  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end

  let(:user)                { responder }
  let(:global_nav)          { instance_double GlobalNavManager,
                                      user: user,
                                      request: request }
  let(:incoming_cases_page) { described_class.new(
                                name: :incoming_cases,
                                parent: global_nav,
                                attrs: config.pages.incoming_cases
                              ) }
  let(:open_cases_page)     { described_class.new(
                                name: :open_cases,
                                parent: global_nav,
                                attrs: config.pages.open_cases
                              ) }
  let(:closed_cases_page)   { described_class.new(
                                name: :closed_cases,
                                parent: global_nav,
                                attrs: config.pages.closed_cases
                              ) }
  let(:stats_page)          { described_class.new(
                                name: :stats,
                                parent: global_nav,
                                attrs: config.pages.stats_page
                              ) }
  let(:in_time_tab) { instance_double(GlobalNavManager::Tab,
                                      fullpath: 'in_time_fullpath',
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
    describe 'tabs' do
      it 'creates tab objects for the list provided' do
        expect(open_cases_page.tabs).to eq [in_time_tab, late_tab]
      end
    end

    describe 'visibility' do
      it 'uses user team(s) to determine visibility' do
        expect(press_officer).not_to be_a_manager
        expect(press_officer.teams.pluck :code).to include 'PRESS-OFFICE'
        allow(global_nav).to receive(:user).and_return(press_officer)

        expect(incoming_cases_page.visible?).to be true
        expect(open_cases_page.visible?).to     be true
        expect(closed_cases_page.visible?).to   be true
        expect(stats_page.visible?).to          be false
      end

      it 'uses user role(s) to determine visibility' do
        expect(disclosure_bmt_user).to be_a_manager
        expect(disclosure_bmt_user.teams.pluck :code).not_to include 'DISCLOSURE'
        allow(global_nav).to receive(:user).and_return(disclosure_bmt_user)

        expect(incoming_cases_page.visible?).to be false
        expect(open_cases_page.visible?).to     be true
        expect(closed_cases_page.visible?).to   be true
        expect(stats_page.visible?).to          be true
      end
    end

    describe 'scopes' do
      context 'press officer user' do
        let(:user) { press_officer }

        it 'sets the scopes using the users team' do
          expect(incoming_cases_page.scope_names).to eq ['incoming_for_press_office']
        end
      end

      context 'responder' do
        let(:user) { responder }

        it 'sets the scopes using the users role' do
          expect(open_cases_page.scope_names).to eq ['opened']
        end
      end

      context 'disclosure specialist' do
        let(:user) { disclosure_specialist_bmt }

        it 'merges scope_names' do
          expect(open_cases_page.scope_names).to match_array ['opened', 'flagged']
        end
      end
    end
  end

  describe '#scope_names' do
    it 'returns the scope_names' do
      expect(open_cases_page.scope_names).to eq ['opened']
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
        expect(open_cases_page.fullpath).to eq 'in_time_fullpath'
      end
    end
  end

  describe '#fullpath_with_query' do
    let(:request) { instance_double ActionDispatch::Request,
                                    path: '/cases/open',
                                    fullpath: '/cases/open',
                                    query_parameters: {
                                      'foo' => 'bar',
                                      'page' => '2'
                                    } }

    context 'on a page with tabs' do
      it 'returns the path of the first tab' do
        expect(open_cases_page.fullpath_with_query).to eq 'in_time_fullpath?foo=bar'
      end
    end
  end

  let(:finder) { instance_double CaseFinderService }

  describe '#finder' do
    let(:cfs) { instance_double(CaseFinderService) }

    before do
      allow(cfs).to receive(:for_scopes_with_or).and_return(cfs)
      allow(global_nav).to receive(:finder).and_return(cfs)
    end

    it 'returns the CaseFinderService received from the global nav' do
      result = open_cases_page.finder
      expect(global_nav).to have_received(:finder)
      expect(result).to be cfs
    end

    it 'calls for_scopes on the finder' do
      open_cases_page.finder
      expect(cfs).to have_received(:for_scopes_with_or).with(['opened'])
    end
  end

  describe '#cases' do
    it 'returns the cases from the finder' do
      finder = instance_double CaseFinderService,
                               scope: double('Case::ActiveRecord_Relation')
      allow(open_cases_page).to receive(:finder).and_return(finder)
      expect(open_cases_page.cases).to eq finder.scope
    end
  end

  describe '#matches_path?' do
    context 'no format specified' do
      it 'returns true if the paths match' do
        expect(open_cases_page.matches_path? 'in_time_fullpath').to be true
      end
    end

    context 'csv format specified' do
      it 'returns true if the paths match' do
        expect(open_cases_page.matches_path? 'in_time_fullpath.csv').to be true
      end
    end
  end
end
