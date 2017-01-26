require 'rails_helper'

RSpec.describe AssignmentNotificationJob, type: :job do
  describe '.perform_later' do
    it 'enqueues a job' do
      expect { AssignmentNotificationJob.perform_later }
        .to have_enqueued_job.on_queue('correspondence_tool_staff_test_mailers')
    end
  end
end
