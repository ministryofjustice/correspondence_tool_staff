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

  let(:incoming_cases_page) do
    GlobalNavManager::Page.new :new_cases,
                               'New cases',
                               incoming_cases_path,
                               {},
                               double('User')
  end
  let(:open_cases_page) do
    GlobalNavManager::Page.new :open_cases,
                               'Open cases',
                               [open_cases_path],
                               {},
                               double('User')
  end
  let(:my_open_cases_page) do
    GlobalNavManager::Page.new :my_open_cases,
                               'My open cases',
                               [my_open_cases_path],
                               {},
                               double('User')
  end
  let(:closed_cases_page) do
    GlobalNavManager::Page.new :closed_cases,
                               'Closed cases',
                               closed_cases_path,
                               {},
                               double('User')
  end
  let(:request) { instance_double ActionDispatch::Request,
                                  path: '/cases/open',
                                  fullpath: '/cases/open?timeliness=in_time' }
  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:approver)  { create :approver }

  describe 'instantiation' do
    context 'manager user' do
      it 'instantiates with the manager pages' do
        gnm = GlobalNavManager.new(manager, request)
        expect(gnm.nav_pages).to eq [open_cases_page, closed_cases_page]
      end
    end

    context 'responder user' do
      it 'instantiates with the responder pages' do
        gnm = GlobalNavManager.new(responder, request)
        expect(gnm.nav_pages).to eq [open_cases_page, closed_cases_page]
      end


    end

    context 'approver user' do
      it 'instantiates with the responder pages' do
        gnm = GlobalNavManager.new(approver, request)
        expect(gnm.nav_pages).to eq [incoming_cases_page,
                                     open_cases_page,
                                     my_open_cases_page,
                                     closed_cases_page]
      end
    end
  end

  describe '#each' do
    let(:gnm) { GlobalNavManager.new(responder, request) }

    it 'yields each page' do
      page1 = double GlobalNavManager::Page
      page2 = double GlobalNavManager::Page
      gnm.instance_eval { @nav_pages = [page1, page2] }
      expect { |block| gnm.each(&block) }
        .to yield_successive_args page1, page2
    end
  end

  describe '#current_page' do
    let(:gnm) { GlobalNavManager.new(responder, request) }

    it 'returns the current page' do
      page = double GlobalNavManager::Page
      allow(GlobalNavManager::Page).to receive(:new).and_return(page)

      expect(gnm.current_page).to eq page
      expect(GlobalNavManager::Page)
        .to have_received(:new)
              .with(:open_cases,
                    'Open cases',
                    '/cases/open',
                    Settings.global_navigation.pages[:open_cases][:tabs],
                    responder)
    end
  end

  describe '#current_tab' do
    let!(:gnm) { GlobalNavManager.new(responder, request) }

    it 'returns the current tab' do
      tab = double GlobalNavManager::Tab, url: '/cases/open?timeliness=in_time'
      page = double GlobalNavManager::Page, tabs: [tab]
      allow(gnm).to receive(:current_page).and_return(page)

      expect(gnm.current_tab).to eq tab
    end
  end

  describe '#current_cases_finder' do
    let(:gnm)    { GlobalNavManager.new(responder, request) }
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
