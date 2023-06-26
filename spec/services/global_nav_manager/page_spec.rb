require "rails_helper"

describe GlobalNavManager::Page do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:finder) { instance_double CaseFinderService }
  let(:disclosure_bmt_user) { find_or_create :disclosure_bmt_user }
  let(:disclosure_specialist_bmt) { find_or_create :disclosure_specialist_bmt }
  let(:press_officer)         { find_or_create :press_officer }
  let(:responder)             { find_or_create :foi_responder }
  let(:request)               do
    instance_double ActionDispatch::Request,
                    path: "/cases/open",
                    fullpath: "/cases/open",
                    query_parameters: {}
  end

  let(:settings) do
    YAML.load(ERB.new(<<~ERB).result)
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
    ERB
  end
  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end

  let(:user)                { responder }
  let(:global_nav)          do
    instance_double GlobalNavManager,
                    user:,
                    request:
  end
  let(:incoming_cases_page) do
    described_class.new(
      name: :incoming_cases,
      parent: global_nav,
      attrs: config.pages.incoming_cases,
    )
  end
  let(:open_cases_page) do
    described_class.new(
      name: :open_cases,
      parent: global_nav,
      attrs: config.pages.open_cases,
    )
  end
  let(:closed_cases_page) do
    described_class.new(
      name: :closed_cases,
      parent: global_nav,
      attrs: config.pages.closed_cases,
    )
  end
  let(:stats_page) do
    described_class.new(
      name: :stats,
      parent: global_nav,
      attrs: config.pages.stats_page,
    )
  end
  let(:in_time_tab) do
    instance_double(GlobalNavManager::Tab,
                    fullpath: "in_time_fullpath",
                    visible?: true)
  end
  # url: :in_time_tab_url) }
  let(:late_tab) do
    instance_double(GlobalNavManager::Tab,
                    fullpath: :late_fullpath,
                    visible?: true)
  end

  before do
    allow(GlobalNavManager::Tab).to receive(:new)
                                      .with(hash_including(name: :in_time))
                                      .and_return(in_time_tab)
    allow(GlobalNavManager::Tab).to receive(:new)
                                      .with(hash_including(name: :late))
                                      .and_return(late_tab)
    allow(CaseFinderService).to receive(:new)
                                  .and_return(instance_spy(CaseFinderService))
  end

  describe "initialization" do
    describe "tabs" do
      it "creates tab objects for the list provided" do
        expect(open_cases_page.tabs).to eq [in_time_tab, late_tab]
      end
    end

    describe "visibility" do
      it "uses user team(s) to determine visibility" do
        expect(press_officer).not_to be_a_manager
        expect(press_officer.teams.pluck(:code)).to include "PRESS-OFFICE"
        allow(global_nav).to receive(:user).and_return(press_officer)

        expect(incoming_cases_page.visible?).to be true
        expect(open_cases_page.visible?).to     be true
        expect(closed_cases_page.visible?).to   be true
        expect(stats_page.visible?).to          be false
      end

      it "uses user role(s) to determine visibility" do
        expect(disclosure_bmt_user).to be_a_manager
        expect(disclosure_bmt_user.teams.pluck(:code)).not_to include "DISCLOSURE"
        allow(global_nav).to receive(:user).and_return(disclosure_bmt_user)

        expect(incoming_cases_page.visible?).to be false
        expect(open_cases_page.visible?).to     be true
        expect(closed_cases_page.visible?).to   be true
        expect(stats_page.visible?).to          be true
      end
    end

    describe "scopes" do
      context "when press officer user" do
        let(:user) { press_officer }

        it "sets the scopes using the users team" do
          expect(incoming_cases_page.__send__(:scope_names)).to eq %w[incoming_for_press_office]
        end
      end

      context "when responder" do
        let(:user) { responder }

        it "sets the scopes using the users role" do
          expect(open_cases_page.__send__(:scope_names)).to eq %w[opened]
        end
      end

      context "when disclosure specialist" do
        let(:user) { disclosure_specialist_bmt }

        it "merges scope_names" do
          expect(open_cases_page.__send__(:scope_names)).to match_array %w[opened flagged]
        end
      end
    end
  end

  describe "#scope_names" do
    it "returns the scope_names" do
      expect(open_cases_page.__send__(:scope_names)).to eq %w[opened]
    end
  end

  describe "#path" do
    it "returns the path" do
      expect(open_cases_page.path).to eq "/opened"
    end
  end

  describe "#fullpath" do
    context "when on a page with no tabs" do
      it "returns the page's path" do
        expect(closed_cases_page.fullpath).to eq "/closed"
      end
    end

    context "when on a page with tabs" do
      it "returns the path of the first tab" do
        expect(open_cases_page.fullpath).to eq "in_time_fullpath"
      end
    end
  end

  describe "#fullpath_with_query" do
    let(:request) do
      instance_double ActionDispatch::Request,
                      path: "/cases/open",
                      fullpath: "/cases/open",
                      query_parameters: {
                        "foo" => "bar",
                        "page" => "2",
                      }
    end

    context "when on a page with tabs" do
      it "returns the path of the first tab" do
        expect(open_cases_page.fullpath_with_query).to eq "in_time_fullpath?foo=bar"
      end
    end
  end

  describe "#finder" do
    let(:cfs) { instance_double(CaseFinderService) }

    before do
      allow(cfs).to receive(:for_scopes).and_return(cfs)
      allow(global_nav).to receive(:finder).and_return(cfs)
    end

    it "returns the CaseFinderService received from the global nav" do
      result = open_cases_page.finder
      expect(global_nav).to have_received(:finder)
      expect(result).to be cfs
    end

    it "calls for_scopes on the finder" do
      open_cases_page.finder
      expect(cfs).to have_received(:for_scopes).with(%w[opened])
    end
  end

  describe "#cases" do
    it "returns the cases from the finder" do
      finder = instance_double CaseFinderService,
                               scope: double("Case::ActiveRecord_Relation") # rubocop:disable RSpec/VerifiedDoubles
      allow(open_cases_page).to receive(:finder).and_return(finder)
      expect(open_cases_page.cases).to eq finder.scope
    end
  end

  describe "#matches_path?" do
    context "when no format specified" do
      it "returns true if the paths match" do
        expect(open_cases_page.matches_path?("in_time_fullpath")).to be true
      end
    end

    context "when csv format specified" do
      it "returns true if the paths match" do
        expect(open_cases_page.matches_path?("in_time_fullpath.csv")).to be true
      end
    end
  end
end
