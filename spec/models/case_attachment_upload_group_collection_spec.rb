require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseAttachmentUploadGroupCollection do
  before(:all) do
    @upload_group_1 = "20170608101112"
    @upload_group_2 = "20170612114201"
    @timestamp_1 = "08 Jun 2017 11:11"
    @timestamp_2 = "12 Jun 2017 12:42"
    @kase = create :case_with_response
    @responder_1 = @kase.responding_team.users.first
    @responder_2 = create(:responder,
                          responding_teams: @responder_1.responding_teams)
    @kase.attachments.first.update!(upload_group: @upload_group_1, user_id: @responder_1.id)

    2.times do
      @kase.attachments << create(:correspondence_response, upload_group: @upload_group_1, user_id: @responder_1.id)
    end

    2.times do
      @kase.attachments << create(:correspondence_response, upload_group: @upload_group_2, user_id: @responder_2.id)
    end
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  describe "#each" do
    it "verifies that the before all set up has been done correctly" do
      expect(@upload_group_1).not_to eq @upload_group_2
      expect(@responder_1).not_to eq @responder_2
      expect(@kase.attachments.size).to eq 5
      expect(@kase.attachments.order(:upload_group, :id).map(&:upload_group)).to eq %w[20170612114201 20170612114201 20170608101112 20170608101112 20170608101112]
      expect(@kase.attachments.order(:upload_group, :id).map(&:user_id)).to eq [@responder_2.id, @responder_2.id, @responder_1.id, @responder_1.id, @responder_1.id]
    end

    it "returns date_time once for each group in reverse time order" do
      yielded_timestamps = []
      @kase.upload_response_groups.each { |ug| yielded_timestamps << ug.date_time }
      expect(yielded_timestamps).to eq [@timestamp_2, @timestamp_1]
    end

    it "returns a user object for each group" do
      users = []
      @kase.upload_response_groups.each { |ug| users << ug.user }
      expect(users).to eq [@responder_2, @responder_1]
    end

    it "returns a team name for each group" do
      team_names = []
      expect(@kase).to receive(:team_for_user).exactly(2).and_return(create(:business_unit, name: "Team 1"), create(:business_unit, name: "Team 2"))
      @kase.upload_response_groups.each { |ug| team_names << ug.team_name }
      expect(team_names).to match_array ["Team 1", "Team 2"]
    end

    it "returns a collection of CaseAttachments for each group" do
      collections = []
      @kase.upload_response_groups.each { |ug| collections << ug.collection }
      expect(collections.size).to eq 2
      expect(collections.first).to be_instance_of(Array)
      expect(collections.first.map(&:class)).to eq [CaseAttachment, CaseAttachment]
      expect(collections.last).to be_instance_of(Array)
      expect(collections.last.map(&:class)).to eq [CaseAttachment, CaseAttachment, CaseAttachment]
    end
  end

  describe "#for_case_attachment_id" do
    it "returns the upload group containing the case attachment identified by the given id" do
      ca = @kase.attachments[3]
      returned_upload_group = @kase.upload_response_groups.for_case_attachment_id(ca.id)
      expect(returned_upload_group.collection).to include(ca)
    end

    it "raises if the case_attachment id is not in any of the upload groups" do
      ca_id = @kase.attachments.map(&:id).max + 20
      expect {
        @kase.upload_response_groups.for_case_attachment_id(ca_id)
      }.to raise_error ArgumentError, "No upload group contains a case attachment with id #{ca_id}"
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
