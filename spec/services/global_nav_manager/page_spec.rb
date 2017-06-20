require 'rails_helper'


describe GlobalNavManager::Page do

  let(:settings) do
    YAML.load(ERB.new(<<~EOY).result)
      pages:
        closed_cases:
          path: '/closed'
        incoming_cases:
          path: '/incoming'
        open_cases:
          path: '/opened'
      tabs:
        in_time:
          params:
            timeliness: 'in_time'
        late:
          params:
            timeliness: 'late'
      structure:
        '*':
          open_cases:
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

  let(:user_double) { instance_double User }
  let(:open_cases_page) { described_class.new(
                            :open_cases,
                            user_double,
                            [:in_time, :late],
                            config,
                          ) }
  let(:closed_cases_page) { described_class.new(
                              :closed_cases,
                              user_double,
                              [],
                              config,
                            ) }
  let(:in_time_tab) { instance_double(GlobalNavManager::Tab,
                                      url: :in_time_tab_url) }
  let(:late_tab)    { instance_double(GlobalNavManager::Tab) }

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

    describe '#name' do
      it 'returns the name' do
        expect(open_cases_page.name).to eq :open_cases
      end
    end

    describe '#text' do
      it 'returns the text' do
        expect(open_cases_page.text).to eq 'Open cases'
      end
    end

    describe 'tabs' do
      it 'creates tab objects for the list provided' do
        expect(open_cases_page.tabs).to eq [in_time_tab, late_tab]
      end
    end
  end

  describe '#url' do
    context 'on a page with no tabs' do
      it "returns the page's path" do
        expect(closed_cases_page.url).to eq '/closed'
      end
    end

    context 'on a page with tabs' do
      it 'returns the url of the first tab' do
        expect(open_cases_page.url).to eq :in_time_tab_url
      end
    end
  end

  let(:finder) { instance_double CaseFinderService }

  describe '#finder' do
    it 'returns the correct CaseFinderService object' do
      allow(CaseFinderService)
        .to receive_message_chain :new,
                                  :for_user,
                                  for_action: :user_action_finder
      expect(open_cases_page.finder).to eq :user_action_finder
      expect(CaseFinderService.new).to have_received(:for_user).with(user_double)
      expect(CaseFinderService.new.for_user(user_double))
        .to have_received(:for_action).with(:open_cases)
    end
  end

  describe '#matches_path?' do
    it 'returns true if the provided path matches the path of the page' do
      expect(open_cases_page.matches_path? '/opened').to be true
    end
  end
end
