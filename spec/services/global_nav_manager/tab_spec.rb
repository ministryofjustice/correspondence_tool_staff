require 'rails_helper'


describe GlobalNavManager::Tab do
  let(:settings) do
    YAML.load(<<~EOY)
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
        'DACU Disclosure':
          incoming_cases:
          open_cases:
            in_time: 'default'
            late:
          closed_cases:
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

  let(:finder) { instance_double(CaseFinderService,
                                 filter_for_params: :filter_result)}
  let(:tab) { GlobalNavManager::Tab.new "late", 'page_path', finder, config }


  describe 'initialisation' do
    it 'uses the supplied attributes' do
      expect(tab).to have_attributes(
                       name: 'late',
                       finder: :filter_result,
                     )
      expect(tab.params.to_h).to eq timeliness: 'late'
    end
  end

  describe '#url' do
    it 'adds params to the page url' do
      expect(tab.url).to eq 'page_path?timeliness=late'
    end
  end

  describe '#matches_fullpath?' do
    it 'returns true if the given fullpath and our fullpath perfectly match' do
      expect(tab.matches_fullpath?('page_path?timeliness=late')).to be true
    end

    it 'returns true if params match, ignoring pagination params' do
      expect(tab.matches_fullpath?('page_path?timeliness=late&page=3')).to be true
    end

    it 'returns false if non-pagination params are different' do
      expect(tab.matches_fullpath?('page_path?filter=nomnom')).to be false
    end

    it 'returns false if path is different but params are the same' do
      expect(tab.matches_fullpath?('earl?timeliness=late')).to be false
    end
  end
end
