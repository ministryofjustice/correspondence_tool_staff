require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe ReportTypePolicy::Scope do
  describe "report type scope policy" do
    before(:all) do
      DbHousekeeping.clean(seed: true)
      @managing_team = create :team_dacu

      @manager = find_or_create :disclosure_bmt_user
      @responder = find_or_create :branston_user

      create :report_type
      @report1 = create :report_type, standard_report: true, sar: true, foi: true
      @report2 = create :report_type, custom_report: true, sar: true
      @report3 = create :report_type, standard_report: true, foi: true
      @report4 = create :report_type, custom_report: true, offender_sar: true
      @report5 = create :report_type, custom_report: true, offender_sar_complaint: true

      @manager.reload
      @responder.reload
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe "#resolve" do
      context "when managers" do
        it "returns the reports having sar and foi flags" do
          manager_scope = Pundit.policy_scope(@manager, ReportType.all)
          expect(manager_scope).to match_array([@report1, @report2, @report3])
        end
      end

      context "when responders" do
        it "returns the reports having offender_sar flag" do
          responder_scope = Pundit.policy_scope(@responder, ReportType.all)
          expect(responder_scope).to match_array([@report4, @report5])
        end
      end

      context "when user who is both manager and responder" do
        it "returns all the reports" do
          @responder.team_roles << TeamsUsersRole.new(team: @managing_team,
                                                      role: "manager")
          @responder.reload
          resolved_scope = described_class.new(@responder, ReportType.all).resolve
          expect(resolved_scope).to match_array([@report1, @report2, @report3, @report4, @report5])
        end
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
