require 'rails_helper'

describe SearchIndexBuNameUpdaterJob, type: :job do
  include ActiveJob::TestHelper

  let(:responding_team_1)   { create :responding_team }
  let(:responding_team_2)   { create :responding_team }

  let(:k1)    { create :assigned_case, responding_team: responding_team_1, name: 'K1' }
  let(:k2)    { create :assigned_case, responding_team: responding_team_1, name: 'K2'  }
  let(:k3)    { create :assigned_case, responding_team: responding_team_2, name: 'K3' }

  describe '#perform' do
    it 'updates the index for all cases responded to by responding team 1' do
      expect(BusinessUnit).to receive(:find).with(responding_team_1.id).and_return(responding_team_1)
      expect(responding_team_1).to receive(:responding_cases).and_return( [ k1, k2 ])
      expect(k1).to receive(:update_index)
      expect(k2).to receive(:update_index)

      SearchIndexBuNameUpdaterJob.new.perform(responding_team_1.id)
    end

    it 'sets the clean flag on cases it has re-indexed' do
      k1; k2; k3
      SearchIndexBuNameUpdaterJob.new.perform(responding_team_1.id)
      expect(k1.reload).to be_clean
      expect(k2.reload).to be_clean
      expect(k3.reload).to be_dirty
    end
  end
end
