require 'rails_helper'



describe GlobalNavManager::GlobalNavManagerEntry do

  context 'initialized with an array of urls' do
    let(:entry) { GlobalNavManager::GlobalNavManagerEntry.new('Cases', ['cases_path', 'root_path', 'other_path']) }

    describe '#text' do
      it 'returns the text' do
        expect(entry.text).to eq 'Cases'
      end
    end

    describe '#urls' do
      it 'returns an array of urls' do
        expect(entry.urls).to eq ['cases_path', 'root_path', 'other_path']
      end
    end

    describe '#url' do
      it 'returns the first url' do
        expect(entry.url).to eq 'cases_path'
      end
    end
  end

  context 'intialized with just one url' do
    let(:entry) { GlobalNavManager::GlobalNavManagerEntry.new('Cases', 'cases_path') }

    describe '#text' do
      it 'returns the text' do
        expect(entry.text).to eq 'Cases'
      end
    end

    describe '#urls' do
      it 'returns an array of one url' do
        expect(entry.urls).to eq ['cases_path']
      end
    end

    describe '#url' do
      it 'returns the  url' do
        expect(entry.url).to eq 'cases_path'
      end
    end
  end
end


describe GlobalNavManager do
  include Rails.application.routes.url_helpers

  # we need to add in equality matcher for GlobalNavManagerEntry here just for testing
  class GlobalNavManager::GlobalNavManagerEntry
    def ==(other)
      @text == other.text && @urls == other.urls
    end
  end

  let(:user) { build :user}
  let(:gnm) { GlobalNavManager.new(user) }

  describe '#each' do
    let(:entry_1) { GlobalNavManager::GlobalNavManagerEntry.new(I18n.t('nav.cases'), [cases_path, root_path]) }
    let(:entry_2) { GlobalNavManager::GlobalNavManagerEntry.new(I18n.t('nav.closed_cases'), closed_cases_path) }

    it 'yeilds for every entry in the Nav Bar' do
      expect { |block| gnm.each(&block) }.to yield_successive_args(entry_1, entry_2)
    end
  end
end
