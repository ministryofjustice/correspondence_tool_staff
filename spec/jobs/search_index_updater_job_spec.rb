require 'rails_helper'

describe SearchIndexUpdaterJob, type: :job do
  include ActiveJob::TestHelper

  let!(:k1)     { create :case, :clean }
  let!(:k2)     { create :case }
  let!(:k3)     { create :case }
  let!(:k4)     { create :case, :clean }


  describe '#perform' do
    it 'processes k1 and k4' do
      expect(Case::Base).to receive(:where).with({dirty: true}).and_return([k2, k3])

      expect(k1).not_to receive(:update_index)
      expect(k4).not_to receive(:update_index)
      expect(k2).to receive(:update_index)
      expect(k3).to receive(:update_index)

      SearchIndexUpdaterJob.new.perform
    end

    it 'sets k1 and k4 to clean' do
      SearchIndexUpdaterJob.new.perform
      expect(k1.reload).to be_clean
      expect(k4.reload).to be_clean
    end
  end
end
