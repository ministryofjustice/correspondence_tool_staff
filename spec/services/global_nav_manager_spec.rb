require 'rails_helper'

# Require these so that class GlobalNavManager is created before our
# monkey-patch to define == below.
require 'global_nav_manager'
require 'global_nav_manager/page'

describe GlobalNavManager do
  include Rails.application.routes.url_helpers

  # we need to add in equality matcher for Page here just for testing
  class GlobalNavManager::Page
    def ==(other)
      @text == other.text && @urls == other.urls
    end
  end

  let(:request) { instance_double ActionDispatch::Request,
                                  path: '/cases/open',
                                  fullpath: '/cases/open?timeliness=in_time' }
  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:disclosure_specialist)  { create :disclosure_specialist }

  let(:settings) do
    YAML.load(ERB.new(<<~EOY).result)
      pages:
        closed_cases:
          path: '/closed'
        opened_cases:
          path: '/opened'
        incoming_cases:
          path: '/incoming'
      tabs:
        in_time:
          params:
            timeliness: 'in_time'
        late:
          params:
            timeliness: 'late'
      structure:
        'Disclosure':
          incoming_cases:
          opened_cases:
            in_time: 'default'
            late:
          closed_cases:
        '*':
          opened_cases:
            in_time: 'default'
            late:
          closed_cases:
     EOY
  end
  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end

  let(:incoming_page) { instance_double GlobalNavManager::Page,
                                        'incoming cases page' }
  let(:open_page)   { instance_double GlobalNavManager::Page,
                                      'open cases page' }
  let(:closed_page)   { instance_double GlobalNavManager::Page,
                                        'closed cases page' }
  let(:gnm) { GlobalNavManager.new(responder, request, config) }

  before do
    allow_any_instance_of(CaseFinderService)
      .to receive_message_chain(:for_user, :for_action, :filter_for_params)
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(:incoming_cases, any_args())
                                       .and_return(incoming_page)
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(:opened_cases, any_args())
                                       .and_return(open_page)
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(:closed_cases, any_args())
                                       .and_return(closed_page)
  end

  describe 'instantiation' do
    context 'user has structure for their team' do
      let(:user) { disclosure_specialist }

      it 'creates the pages for the structure that matches the users team' do
        gnm = GlobalNavManager.new(user, request, config)
        expect(GlobalNavManager::Page)
          .to have_received(:new)
                .with(:incoming_cases, user, [], config)
        expect(GlobalNavManager::Page)
          .to have_received(:new)
                .with(:opened_cases, user, [:in_time, :late], config)
        expect(GlobalNavManager::Page)
          .to have_received(:new)
                .with(:closed_cases, user, [], config)
        expect(gnm.nav_pages).to eq [incoming_page, open_page, closed_page]
      end
    end

    context 'user has no structure defined specifically for their team' do
      let(:user) { manager }

      it 'creates the pages for the default "*" structure' do
        gnm = GlobalNavManager.new(user, request, config)
        expect(GlobalNavManager::Page)
          .to have_received(:new)
                .with(:opened_cases, user, [:in_time, :late], config)
        expect(GlobalNavManager::Page)
          .to have_received(:new)
                .with(:closed_cases, user, [], config)
        expect(gnm.nav_pages).to eq [open_page, closed_page]
      end
    end
  end

  describe '#each' do
    it 'yields each page' do
      page1 = double GlobalNavManager::Page
      page2 = double GlobalNavManager::Page
      gnm.instance_eval { @nav_pages = [page1, page2] }
      expect { |block| gnm.each(&block) }
        .to yield_successive_args page1, page2
    end
  end

  describe '#current_page' do
    before do
      allow(closed_page).to receive(:matches_path?).and_return(false)
      allow(open_page).to receive(:matches_path?).and_return(true)
    end


    it 'returns the current page' do
      expect(gnm.current_page).to eq open_page
    end
  end

  describe '#current_tab' do

    it 'returns the current tab' do
      tab = double GlobalNavManager::Tab, matches_fullpath?: true
      page = double GlobalNavManager::Page, tabs: [tab]
      allow(gnm).to receive(:current_page).and_return(page)

      expect(gnm.current_tab).to eq tab
    end

    it 'calls matches_fullpath? on the tab' do
      tab = double GlobalNavManager::Tab, matches_fullpath?: true
      page = double GlobalNavManager::Page, tabs: [tab]
      allow(gnm).to receive(:current_page).and_return(page)

      gnm.current_tab
      expect(tab).to have_received(:matches_fullpath?).with(request.fullpath)
    end

    it 'returns nil if no tab matches' do
      tab = double GlobalNavManager::Tab, matches_fullpath?: false
      page = double GlobalNavManager::Page, tabs: [tab]
      allow(gnm).to receive(:current_page).and_return(page)

      expect(gnm.current_tab).to be_nil
    end
  end

  describe '#current_cases_finder' do
    let(:finder) { double CaseFinderService }

    context 'page with no tabs' do
      let(:page) { double GlobalNavManager::Page, finder: finder }

      before do
        allow(gnm).to receive(:current_page).and_return(page)
        allow(gnm).to receive(:current_tab).and_return(nil)
      end

      it 'returns the current page finder' do
        expect(gnm.current_cases_finder).to eq finder
      end
    end

    context 'page with tabs' do
      let(:tab) { double GlobalNavManager::Tab, finder: finder }

      before do
        allow(gnm).to receive(:current_tab).and_return(tab)
      end

      it 'returns the current tab finder' do
        expect(gnm.current_cases_finder).to eq finder
      end
    end
  end
end
