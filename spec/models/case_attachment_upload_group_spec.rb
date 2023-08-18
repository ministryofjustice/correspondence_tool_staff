require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseAttachmentUploadGroup do
  before(:all) do
    DbHousekeeping.clean

    @upload_group = "20170608101112"
    @kase = create :case_with_response
    @responder = @kase.responding_team.users.first
    @kase.attachments.first.update!(upload_group: @upload_group, user_id: @responder.id)

    2.times do
      @kase.attachments << create(:correspondence_response, upload_group: @upload_group, user_id: @responder.id)
    end
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  let(:upload_group) { described_class.new([@upload_group, @responder.id], :responder, @kase, @kase.attachments) }

  describe "#user" do
    it "returns the user specified by the id" do
      expect(upload_group.user).to eq @responder
    end
  end

  describe "#collection" do
    it "returns the same collection as it was initialisec with" do
      expect(upload_group.collection).to eq @kase.attachments
    end
  end

  # describe "date_time" do
  # it "returns the formatted upload group time converted to BST" do
  #   debugger
  # expect(upload_group.date_time).to eq "08 Jun 2017 11:11"
  # end
  # end

  describe "#delete!" do
    it "deletes the specified case attachment from the collection" do
      expect(upload_group.collection.size).to eq 3
      original_ids = upload_group.collection.map(&:id)
      upload_group.delete!(original_ids.first)
      expect(upload_group.collection.map(&:id)).to eq [original_ids[1], original_ids[2]]
    end

    it "raises if case_attachment id is not in collection" do
      non_existing_id = upload_group.collection.map(&:id).max + 10
      expect {
        upload_group.delete!(non_existing_id)
      }.to raise_error ArgumentError, "Specified CaseAttachmentId (#{non_existing_id}) not in collection"
    end
  end

  describe "#any?" do
    it "returns true if records in the collection" do
      expect(upload_group.any?).to be true
    end

    it "returns false if no records in the collection" do
      ids = upload_group.collection.map(&:id)
      ids.each do |ca_id|
        upload_group.delete!(ca_id)
      end
      expect(upload_group.any?).to be false
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
