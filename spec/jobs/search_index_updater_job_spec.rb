require 'rails_helper'

describe PdfMakerJob, type: :job do
  include ActiveJob::TestHelper

  let!(:k1)     { create :case, :clean }
  let!(:k2)     { create :case }
  let!(:k3)     { create :case }
  let!(:k4)     { create :case, :clean }


  describe '#perform' do
    it 'processes k1 and k4' do
      expect(SearchIndex).not_to receive(:update_document).with(k1)
      expect(SearchIndex).not_to receive(:update_document).with(k4)
      expect(SearchIndex).to receive(:update_document).with(k2)
      expect(SearchIndex).to receive(:update_document).with(k3)

      SearchIndexUpdaterJob.new.perform
    end

    it 'sets k1 and k4 to clean' do
      allow(SearchIndex).to receive(:update_document)
      SearchIndexUpdaterJob.new.perform
      expect(k1.reload).to be_clean
      expect(k4.reload).to be_clean
    end
  end
end
