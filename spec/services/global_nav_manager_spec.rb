require "rails_helper"

describe GlobalNavManager do
  include Rails.application.routes.url_helpers

  let(:request) do
    instance_double ActionDispatch::Request,
                    path: "/cases/incoming"
  end
  let(:manager)   { create :manager }
  let(:responder) { find_or_create :foi_responder }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }

  let(:settings) do
    YAML.load(ERB.new(<<~ERB).result)
      pages:
        incoming_cases:
          path: '/incoming'
          filter: incoming_cases
          visibility:
            'DISCLOSURE':
              filter: incoming_cases_disclosure
        opened_cases:
          path: '/opened'
          filter: 'opened_cases'
          tabs:
            in_time:
              filter: in_time
            late:
              filter: late
        closed_cases:
          path: '/closed'
          filter: closed_cases
        stats_page:
          path: '/stats'
          visibility:
            - manager
    ERB
  end
  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end
  let(:pages_config) { config.pages }

  let(:incoming_page) do
    instance_double GlobalNavManager::Page,
                    "incoming cases page",
                    visible?: false
  end
  let(:open_page) do
    instance_double GlobalNavManager::Page,
                    "open cases page",
                    tabs: [],
                    visible?: true
  end
  let(:closed_page) do
    instance_double GlobalNavManager::Page,
                    "closed cases page",
                    tabs: [],
                    visible?: true
  end
  let(:stats_page) do
    instance_double GlobalNavManager::Page,
                    "stats page",
                    visible?: false
  end
  let(:gnm) { described_class.new(responder, request, pages_config) }

  before do
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(hash_including(name: :incoming_cases))
                                       .and_return(incoming_page)
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(hash_including(name: :opened_cases))
                                       .and_return(open_page)
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(hash_including(name: :closed_cases))
                                       .and_return(closed_page)
    allow(GlobalNavManager::Page).to receive(:new)
                                       .with(hash_including(name: :stats_page))
                                       .and_return(stats_page)
  end

  describe "instantiation" do
    it "only exposes visible pages" do
      allow(incoming_page).to receive(:visible?).and_return false
      allow(open_page).to receive(:visible?).and_return true
      allow(closed_page).to receive(:visible?).and_return true
      allow(stats_page).to receive(:visible?).and_return false
      gnm = described_class.new(responder, request, pages_config)
      expect(GlobalNavManager::Page).to have_received(:new)
                                          .with(name: :opened_cases,
                                                parent: gnm,
                                                attrs: pages_config.opened_cases)
      expect(GlobalNavManager::Page).to have_received(:new)
                                          .with(name: :closed_cases,
                                                parent: gnm,
                                                attrs: pages_config.closed_cases)
      expect(gnm.nav_pages).to eq [open_page, closed_page]
    end
  end

  describe "#each" do
    it "yields each page" do
      page1 = instance_double GlobalNavManager::Page
      page2 = instance_double GlobalNavManager::Page
      gnm.instance_eval { @nav_pages = [page1, page2] }
      expect { |block| gnm.each(&block) }
        .to yield_successive_args page1, page2
    end
  end

  describe "#finder" do
    let(:request) do
      instance_double ActionDispatch::Request,
                      path: "/cases/incoming",
                      params: { "state" => "unequivocal" }
    end
    let(:case_finder_service) { instance_double(CaseFinderService) }

    before do
      allow(CaseFinderService).to receive(:new)
                                    .and_return case_finder_service
      allow(case_finder_service).to receive(:for_params)
                                      .and_return case_finder_service
    end

    it "returns a finder" do
      expect(gnm.finder).to eq case_finder_service
    end

    it "customizes for user and params" do
      gnm.finder
      expect(case_finder_service).to have_received(:for_params)
                                       .with({ "state" => "unequivocal" })
    end
  end

  describe "#current_page_or_tab" do
    let(:in_time_tab) do
      instance_double GlobalNavManager::Tab,
                      "open in_time cases tab",
                      visible?: true
    end
    let(:late_tab) do
      instance_double GlobalNavManager::Tab,
                      "open late cases tab",
                      visible?: true
    end

    before do
      allow(open_page).to   receive(:tabs).and_return([in_time_tab, late_tab])
      allow(open_page).to   receive(:tabs).and_return([in_time_tab, late_tab])
      allow(closed_page).to receive(:matches_path?).and_return(false)
      allow(in_time_tab).to receive(:matches_path?).and_return(false)
      allow(late_tab).to    receive(:matches_path?).and_return(false)
    end

    context "when request is for a page" do
      it "returns the current tab" do
        allow(closed_page).to receive(:matches_path?)
                                 .with("/cases/incoming")
                                 .and_return(true)
        expect(gnm.current_page_or_tab).to eq closed_page
      end
    end

    context "when request is for a tab" do
      it "returns the current tab" do
        allow(in_time_tab).to receive(:matches_path?)
                                 .with("/cases/incoming")
                                 .and_return(true)
        expect(gnm.current_page_or_tab).to eq in_time_tab
      end
    end
  end

  describe "#current_page" do
    before do
      allow(closed_page).to receive(:matches_path?).and_return(false)
      allow(open_page).to receive(:matches_path?).and_return(true)
    end

    it "returns the current page" do
      expect(gnm.current_page).to eq open_page
    end
  end
end
