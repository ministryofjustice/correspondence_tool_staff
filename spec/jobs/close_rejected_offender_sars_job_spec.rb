require "rails_helper"

describe CloseRejectedOffenderSarsJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "closes rejected offender_sars received 31 days ago" do
      # Create a rejected offender_sar received 31 days ago
      offender_sar = create(:offender_sar_case, :rejected, received_date: 31.days.ago)

      # Enqueue the job
      CloseRejectedOffenderSarsJob.perform_now

      # Verify that the offender_sar is closed
      expect(offender_sar.reload.current_state).to eq('closed')
    end

    it "does not close offender_sars received less than 31 days ago" do
      # Create a rejected offender_sar received 30 days ago
      offender_sar =  create(:offender_sar_case, :rejected, received_date: 30.days.ago)

      # Enqueue the job
      CloseRejectedOffenderSarsJob.perform_now

      # Verify that the offender_sar is not closed
      expect(offender_sar.reload.current_state).not_to eq('closed')
    end

    it "does not close offender_sars with a state other than 'rejected'" do
      # Create an offender_sar with a state other than 'rejected'
      offender_sar = create(:offender_sar_case, :data_to_be_requested, received_date: 31.days.ago)

      # Enqueue the job
      CloseRejectedOffenderSarsJob.perform_now

      # Verify that the offender_sar is not closed
      expect(offender_sar.reload.current_state).not_to eq('closed')
    end
  end
end
