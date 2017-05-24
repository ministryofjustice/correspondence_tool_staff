require 'rails_helper'


describe GlobalNavManager::Page do

  context 'initialized with an array of urls' do
    let(:page) { described_class.new(
                    :cases,
                    'Cases',
                    ['cases_path', 'root_path', 'other_path'],
                    {},
                    double('User')
                  ) }

    describe '#name' do
      it 'returns the name' do
        expect(page.name).to eq :cases
      end
    end

    describe '#text' do
      it 'returns the text' do
        expect(page.text).to eq 'Cases'
      end
    end

    describe '#urls' do
      it 'returns an array of urls' do
        expect(page.urls).to eq ['cases_path', 'root_path', 'other_path']
      end
    end

    describe '#url' do
      it 'returns the first url' do
        expect(page.url).to eq 'cases_path'
      end
    end
  end

  context 'initalized with just one url' do
    let(:page) { described_class.new(:cases,
                                     'Cases',
                                     'cases_path',
                                     {},
                                     double('User')) }

    describe '#name' do
      it 'returns the name' do
        expect(page.name).to eq :cases
      end
    end

    describe '#text' do
      it 'returns the text' do
        expect(page.text).to eq 'Cases'
      end
    end

    describe '#urls' do
      it 'returns an array of one url' do
        expect(page.urls).to eq ['cases_path']
      end
    end

    describe '#url' do
      it 'returns the  url' do
        expect(page.url).to eq 'cases_path'
      end
    end
  end

  let(:finder) { instance_double CaseFinderService }

  describe '#tabs' do
    let(:user) { double User }
    let(:page) { described_class.new(:cases,
                                     'Cases',
                                     'cases_path',
                                     { in_time: { timeliness: 'in_time' } },
                                     user) }

    it 'returns a tab object' do
      tab = instance_double GlobalNavManager::Tab
      allow(GlobalNavManager::Tab).to receive(:new).and_return(tab)
      allow(page).to receive(:finder).and_return(finder)
      expect(page.tabs.first).to eq tab
      expect(GlobalNavManager::Tab).to have_received(:new).with(
                                         :in_time,
                                         'cases_path',
                                         finder,
                                         { timeliness: 'in_time' }
                                       )
    end
  end

  describe '#finder' do
    let(:user) { double User }
    let(:page) { described_class.new(:cases,
                                     'Cases',
                                     'cases_path',
                                     { in_time: { timeliness: 'in_time' } },
                                     user) }

    it 'returns the correct CaseFinderService object' do
      allow(CaseFinderService).to receive(:new).and_return(finder)
      expect(page.finder).to eq finder
      expect(CaseFinderService).to have_received(:new).with(user, :cases)
    end
  end
end
