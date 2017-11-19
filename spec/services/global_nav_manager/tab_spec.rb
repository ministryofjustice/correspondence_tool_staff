require 'rails_helper'


describe GlobalNavManager::Tab do
  let(:settings) do
    YAML.load(<<~EOY)
      pages:
        open_cases:
          path: '/opened'
          scope: opened
          tabs:
            in_time:
              scope: in_time
            late:
              scope: late
     EOY
  end

  let(:config) do
    Config::Options.new.tap do |config|
      config.add_source! settings
      config.reload!
    end
  end

  let(:responder)             { create :responder }
  let(:request)               { instance_double ActionDispatch::Request,
                                                path: '/cases/open',
                                                fullpath: '/cases/open',
                                                query_parameters: {} }
  let(:global_nav)  { instance_double GlobalNavManager,
                                      user: responder,
                                      request: request }
  let(:parent_page) { instance_double GlobalNavManager::Page,
                                      scopes: ['open'],
                                      path: '/opened' }
  let(:tab) { GlobalNavManager::Tab.new 'late',
                                        parent_page,
                                        config.pages.open_cases.tabs.late }

  it 'inherits from GlobalNavManager::Page' do
    expect(tab).to be_a GlobalNavManager::Page
  end

  describe 'initialisation' do
    it 'uses the supplied attributes' do
      expect(tab).to have_attributes name: 'late'
    end
  end

  describe '#fullpath' do
    it 'joins parent path with ours' do
      expect(tab.fullpath).to eq '/opened/late'
    end
  end
end
