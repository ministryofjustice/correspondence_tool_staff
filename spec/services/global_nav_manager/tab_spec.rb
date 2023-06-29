require "rails_helper"

describe GlobalNavManager::Tab do
  let(:settings) do
    YAML.load(<<~CONFIG)
      pages:
        open_cases:
          path: '/opened'
          scope: opened
          tabs:
            in_time:
              scope: in_time
            late:
              scope: late
    CONFIG
  end

  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end

  let(:responder)             { find_or_create :foi_responder }
  let(:request)               do
    instance_double ActionDispatch::Request,
                    path: "/cases/open",
                    fullpath: "/cases/open",
                    query_parameters: {}
  end
  let(:global_nav) do
    instance_double GlobalNavManager,
                    user: responder,
                    request:
  end
  let(:parent_page) do
    instance_double GlobalNavManager::Page,
                    scope_names: %w[open],
                    path: "/opened"
  end
  let(:tab) do
    described_class.new name: "late",
                        parent: parent_page,
                        attrs: config.pages.open_cases.tabs.late
  end

  it "inherits from GlobalNavManager::Page" do
    expect(tab).to be_a GlobalNavManager::Page
  end

  describe "initialisation" do
    it "uses the supplied attributes" do
      expect(tab).to have_attributes name: "late"
    end
  end

  describe "#fullpath" do
    it "joins parent path with ours" do
      expect(tab.fullpath).to eq "/opened/late"
    end
  end

  describe "#count" do
    it "has a count that can be set" do
      tab.set_count(3)
      expect(tab.count).to eq(3)
    end
  end
end
