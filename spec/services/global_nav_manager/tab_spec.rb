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
      gnm = GlobalNavManager::Tab.new("name", "url", finder, {param: :value})
      expect(gnm.url).to eq 'url?param=value'
    end
  end
end
