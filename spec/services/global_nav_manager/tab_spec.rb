require 'rails_helper'


describe GlobalNavManager::Tab do
  let(:finder) { instance_double(CaseFinderService,
                                 filter_for_params: :filter_result)}

  describe 'initialisation' do
    it 'uses the supplied attributes' do
      expect(
        GlobalNavManager::Tab.new("late", "url", finder, {})
      ).to have_attributes(
             name: 'late',
             finder: :filter_result,
             params: {}
           )
    end
  end

  describe '#url' do
    it 'adds params to the base url' do
      tab = GlobalNavManager::Tab.new("name", "url", finder, {param: :value})
      expect(tab.url).to eq 'url?param=value'
    end
  end

  describe '#matches_url?' do
    it 'returns true if the given url and our url perfectly match' do
      tab = GlobalNavManager::Tab.new("name", "url", finder, {filter: :value})
      expect(tab.matches_url?('url?filter=value')).to be true
    end

    it 'returns true if params match, ignoring pagination params' do
      tab = GlobalNavManager::Tab.new("name", "url", finder, {filter: :value})
      expect(tab.matches_url?('url?filter=value&page=3')).to be true
    end

    it 'returns false if non-pagination params are different' do
      tab = GlobalNavManager::Tab.new("name", "url", finder, {filter: :value})
      expect(tab.matches_url?('url?filter=nomnom')).to be false
    end

    it 'returns false if path is different but params are the same' do
      tab = GlobalNavManager::Tab.new("name", "url", finder, {filter: :value})
      expect(tab.matches_url?('earl?filter=value')).to be false
    end
  end
end
