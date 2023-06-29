require "rails_helper"

class DummyCase < Case::Base
  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party: :boolean,
                 reply_method: :string,
                 num_clicks: :integer

  has_paper_trail only: %i[
    name
    email
    message
    received_date
    properties
    subject
    subject_full_name
  ]

  def self.type_abbreviation
    "FOI"
  end
end

describe "papertrail", versioning: true do
  let(:run_time) { Time.zone.local(2018, 4, 20, 10, 27, 33) }

  describe "reify" do
    it "recreates the record and stores the previous values" do
      Timecop.freeze(run_time) do
        kase = create_dummy_case
        expect(kase.received_date).to eq Date.parse("2018-04-19")
        expect(kase.escalation_deadline).to eq Date.parse("2018-04-25")
        expect(kase.internal_deadline).to eq Date.parse("2018-05-03")
        expect(kase.external_deadline).to eq Date.parse("2018-05-18")

        update_dummy_case(kase)
        expect(kase.received_date).to eq Date.parse("2018-04-15")
        expect(kase.escalation_deadline).to eq Date.parse("2018-04-18")
        expect(kase.internal_deadline).to eq Date.parse("2018-04-27")
        expect(kase.external_deadline).to eq Date.parse("2018-05-14")

        reified_kase = kase.versions.last.reify

        expect(reified_kase.name).to eq "Stephen Richards"
        expect(reified_kase.email).to eq "sr@moj.com"
        expect(reified_kase.message).to eq "this is a message"
        expect(reified_kase.subject).to eq "This is the subject"
        expect(reified_kase.subject_full_name).to eq "John Criminal"
        expect(reified_kase.subject_type).to eq "offender"
        expect(reified_kase.third_party).to eq true
        expect(reified_kase.reply_method).to eq "email"
        expect(reified_kase.num_clicks).to eq 0
        expect(reified_kase.escalation_deadline).to eq Date.parse("2018-04-25")
        expect(reified_kase.internal_deadline).to eq Date.parse("2018-05-03")
        expect(reified_kase.external_deadline).to eq Date.parse("2018-05-18")
      end
    end

    it "restores the gov_uk_dates" do
      Timecop.freeze(run_time) do
        kase = create_dummy_case
        expect(kase.received_date).to eq Date.parse("2018-04-19")
        update_dummy_case(kase)
        expect(kase.received_date).to eq Date.parse("2018-04-15")
        reified_kase = kase.versions.last.reify
        expect(reified_kase.received_date).to eq Date.parse("2018-04-19")
      end
    end
  end

  describe "versioning hash" do
    it "holds the values of the attributes before the change" do
      Timecop.freeze(run_time) do
        kase = create_dummy_case
        update_dummy_case(kase)
        version_hash = CtsPapertrailSerializer.load(kase.versions.last.object)
        expect(version_hash["name"]).to eq "Stephen Richards"
        expect(version_hash["email"]).to eq "sr@moj.com"
        expect(version_hash["message"]).to eq "this is a message"
        expect(version_hash["subject"]).to eq "This is the subject"
        expect(version_hash["subject_full_name"]).to eq "John Criminal"
        expect(version_hash["subject_type"]).to eq "offender"
        expect(version_hash["third_party"]).to eq true
        expect(version_hash["reply_method"]).to eq "email"
        expect(version_hash["num_clicks"]).to eq 0
        expect(version_hash["escalation_deadline"]).to eq "2018-04-25"
        expect(version_hash["internal_deadline"]).to eq "2018-05-03"
        expect(version_hash["external_deadline"]).to eq "2018-05-18"
      end
    end

    it "hold the CORRECT date received" do
      Timecop.freeze(run_time) do
        kase = create_dummy_case
        update_dummy_case(kase)
        version_hash = CtsPapertrailSerializer.load(kase.versions.last.object)
        expect(version_hash["received_date"]).to eq Date.parse("2018-04-19")

        kase.update!(received_date: version_hash["received_date"])
        expect(kase.received_date).to eq Date.parse("2018-04-19")
      end
    end
  end

  def create_dummy_case(options = {})
    received_date = 1.day.ago
    creation_params = {
      name: "Stephen Richards",
      email: "sr@moj.com",
      message: "this is a message",
      received_date:,
      subject: "This is the subject",
      subject_full_name: "John Criminal",
      subject_type: "offender",
      third_party: true,
      reply_method: "email",
      num_clicks: 0,
    }
    creation_params[:creator] = create(:user, :orphan)
    DummyCase.create!(creation_params.merge(options))
  end

  def update_dummy_case(kase, options = {})
    received_date = 5.days.ago
    update_params = {
      name: "John Dunne",
      email: "jd@moj.com",
      message: "This message has been updated",
      received_date:,
      subject: "This subject has been modified",
      subject_full_name: "Jane Criminaless",
      subject_type: "lawuer",
      third_party: false,
      reply_method: "post",
      num_clicks: 3,
      escalation_deadline: Date.new(2018, 4, 18),
      internal_deadline: Date.new(2018, 4, 27),
      external_deadline: Date.new(2018, 5, 14),
    }
    kase.update!(update_params.merge(options))
  end

  def versioning_records(kase_id)
    conn = ActiveRecord::Base.connection
    conn.execute("SELECT * FROM versions where item_id = #{kase_id}")
  end
end
