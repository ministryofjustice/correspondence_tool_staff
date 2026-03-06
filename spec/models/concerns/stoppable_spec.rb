require "rails_helper"

RSpec.describe Stoppable do
  let(:kase) do
    Timecop.freeze(Time.zone.local(2025, 3, 1)) do
      create :sar_case, received_date: Date.new(2025, 3, 1)
    end
  end

  describe "#total_time_stopped" do
    before do
      events = [
        { event: "add_note_to_case" },
        { event: "stop_the_clock", date: "2025-03-05" },
        { event: "restart_the_clock", date: "2025-03-10" },
        { event: "stop_the_clock", date: "2025-03-12" },
        { event: "restart_the_clock", date: "2025-03-15" },
        { event: "stop_the_clock", date: "2025-03-20" },
        { event: "add_note_to_case" },
        { event: "restart_the_clock", date: "2025-03-29" },
        { event: "stop_the_clock", date: "2025-04-01" },
        { event: "restart_the_clock", date: "2025-04-05" },
        { event: "stop_the_clock", date: "2025-04-09" },
        { event: "stop_the_clock", date: "2025-04-10" }, # Bad data test
        { event: "restart_the_clock", date: "2025-04-11" },
        { event: "restart_the_clock", date: "2025-04-11" }, # Bad data test
        { event: "stop_the_clock", date: "2025-04-11" },
      ]

      transitions = events.map.with_index do |e, index|
        {
          event: e[:event],
          to_state: e[:event] == "stop_the_clock" ? "stopped" : "drafting",
          metadata: {
            "details": {
              "#{e[:event]}_date" => e[:date],
            },
            "message": "Spec dummy data - #{e[:event]}",
            "filenames": [],
          },
          sort_key: index + 1,
          case_id: kase.id,
          acting_user_id: 1,
          acting_team_id: 1,
          most_recent: false,
          to_workflow: "standard",
        }
      end

      Timecop.freeze(Time.zone.local(2025, 3, 1)) do
        kase.transitions.create!(transitions)
      end
    end

    it "calculates total time stopped across all stop/restart events" do
      expect(kase.total_time_stopped).to eq(22)
    end

    it "returns 0 if there are no stop/start events" do
      kase.transitions.where(event: %w[restart_the_clock stop_the_clock]).delete_all

      expect(kase.total_time_stopped).to eq(0)
    end
  end
end
