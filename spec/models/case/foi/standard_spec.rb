# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

require "rails_helper"

describe Case::FOI::Standard do
  let(:no_postal)          { build :case, postal_address: nil             }
  let(:no_postal_or_email) { build :case, postal_address: nil, email: nil }
  let(:no_email)           { build :case, email: nil                      }

  context "without a postal or email address" do
    it "is invalid" do
      expect(no_postal_or_email).not_to be_valid
    end
  end

  context "without a postal_address" do
    it "is valid with an email address" do
      expect(no_postal).to be_valid
    end
  end

  context "without an email address" do
    it "is valid with a postal address" do
      expect(no_email).to be_valid
    end
  end

  describe "papertrail versioning", versioning: true do
    before do
      @kase = create :foi_case, name: "aaa", email: "aa@moj.com", received_date: Time.zone.today, subject: "subject A", postal_address: "10 High Street", requester_type: "journalist"
      @kase.update!(name: "bbb", email: "bb@moj.com", received_date: 1.day.ago, subject: "subject B", postal_address: "20 Low Street", requester_type: "offender")
    end

    it "saves all values in the versions object hash" do
      version_hash = YAML.load(@kase.versions.last.object, permitted_classes: [Time, Date])
      expect(version_hash["email"]).to eq "aa@moj.com"
      expect(version_hash["received_date"]).to eq Time.zone.today
      expect(version_hash["subject"]).to eq "subject A"
      expect(version_hash["postal_address"]).to eq "10 High Street"
      expect(version_hash["requester_type"]).to eq "journalist"
    end

    it "can reconsititue a record from a version (except for received_date)" do
      original_kase = @kase.versions.last.reify
      expect(original_kase.email).to eq "aa@moj.com"
      expect(original_kase.subject).to eq "subject A"
      expect(original_kase.postal_address).to eq "10 High Street"
      expect(original_kase.requester_type).to eq "journalist"
    end

    it "reconstitutes the received date" do
      original_kase = @kase.versions.last.reify
      expect(original_kase.received_date).to eq Time.zone.today
    end
  end

  describe "name attribute" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "subject attribute" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_length_of(:subject).is_at_most(100) }
  end

  describe "requester_type" do
    it { is_expected.to validate_presence_of(:requester_type) }

    it {
      expect(subject).to have_enum(:requester_type)
                  .with_values(
                    %w[
                      academic_business_charity
                      journalist
                      member_of_the_public
                      offender
                      solicitor
                      staff_judiciary
                      what_do_they_know
                    ],
                  )
    }
  end

  describe "delivery_method" do
    it { is_expected.to validate_presence_of(:delivery_method) }

    it {
      expect(subject).to have_enum(:delivery_method)
                  .with_values(
                    %w[
                      sent_by_email
                      sent_by_post
                    ],
                  )
    }
  end

  describe "#business_unit_responded_in_time?" do
    before do
      @manager = create :manager
    end

    context "case not yet responded" do
      it "raises" do
        assigned_case = create :assigned_case
        expect {
          assigned_case.business_unit_responded_in_time?
        }.to raise_error ArgumentError, "Cannot call #business_unit_responded_in_time? on a case without a response (Case #{assigned_case.number})"
      end
    end

    context "case has been responded" do
      context "just one assignment to a team" do
        context "in time" do
          context "flagged" do
            it "returns true" do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end

          context "unflagged" do
            it "returns true" do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end
        end

        context "late" do
          context "flagged" do
            it "returns false" do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [14.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 14.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end

          context "unflagged" do
            it "returns false" do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [15.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 15.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end
        end
      end

      context "multiple assignments and rejections" do
        context "in time" do
          context "flagged" do
            it "returns true" do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [12.business_days.ago, 10.business_days.ago, 7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq "rejected"
              expect(responder_assignments[1].state).to eq "rejected"
              expect(responder_assignments[2].state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end

          context "unflagged" do
            it "returns true" do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [12.business_days.ago, 10.business_days.ago, 7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq "rejected"
              expect(responder_assignments[1].state).to eq "rejected"
              expect(responder_assignments[2].state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end
        end

        context "late" do
          context "flagged" do
            it "returns false" do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [17.business_days.ago, 16.business_days.ago, 14.business_days.ago],
                                 responded_time: 1.business_days.ago)
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq "rejected"
              expect(responder_assignments[1].state).to eq "rejected"
              expect(responder_assignments[2].state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 14.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 1.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end

          context "unflagged" do
            it "returns false" do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [17.business_days.ago, 16.business_days.ago, 15.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq "rejected"
              expect(responder_assignments[1].state).to eq "rejected"
              expect(responder_assignments[2].state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 15.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses").last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end
        end
      end
    end
  end

  describe "#business_unit_already_late?" do
    before do
      @manager = create :manager
    end

    context "responded case" do
      it "raises" do
        responded_kase = create :responded_case
        expect {
          responded_kase.business_unit_already_late?
        }.to raise_error ArgumentError, "Cannot call #business_unit_already_late? on a case for which the response has been sent"
      end
    end

    context "open cases" do
      context "just one assignment to responding team" do
        context "in time" do
          context "non trigger cases" do
            it "returns true" do
              Timecop.freeze(Date.new(2020, 8, 19)) do
                # given
                kase = create_case(flagged: false,
                                   assignment_times: [18.business_days.ago])
                expect(kase).not_to be_flagged
                responder_assignments = kase.assignments.responding.order(:id)
                expect(responder_assignments.size).to eq 1
                expect(responder_assignments.first.state).to eq "accepted"

                expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 18.business_days.ago.to_date
                expect(kase.transitions.where(event: "add_responses")).to be_empty

                # then
                expect(kase.business_unit_already_late?).to be false
              end
            end
          end

          context "trigger cases" do
            it "returns true" do
              Timecop.freeze(Date.new(2020, 8, 19)) do
                # given
                kase = create_case(flagged: true,
                                   assignment_times: [8.business_days.ago])
                expect(kase).to be_flagged
                responder_assignments = kase.assignments.responding.order(:id)
                expect(responder_assignments.size).to eq 1
                expect(responder_assignments.first.state).to eq "accepted"

                expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 8.business_days.ago.to_date
                expect(kase.transitions.where(event: "add_responses")).to be_empty

                # then
                expect(kase.business_unit_already_late?).to be false
              end
            end
          end
        end

        context "late" do
          context "non trigger cases" do
            it "returns true" do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [21.business_days.ago])
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 21.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses")).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end

          context "trigger cases" do
            it "returns true" do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [11.business_days.ago])
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 11.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses")).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end
        end
      end

      context "multiple assignments to responding teams" do
        context "in time" do
          context "non trigger cases" do
            it "returns true" do
              Timecop.freeze(Date.new(2020, 8, 19)) do
                # given
                kase = create_case(flagged: false,
                                   assignment_times: [30.business_days.ago, 25.business_days.ago, 18.business_days.ago])
                expect(kase).not_to be_flagged
                responder_assignments = kase.assignments.responding.order(:id)
                expect(responder_assignments.size).to eq 3
                expect(responder_assignments[0].state).to eq "rejected"
                expect(responder_assignments[1].state).to eq "rejected"
                expect(responder_assignments[2].state).to eq "accepted"

                expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 18.business_days.ago.to_date
                expect(kase.transitions.where(event: "add_responses")).to be_empty

                # then
                expect(kase.business_unit_already_late?).to be false
              end
            end
          end

          context "trigger cases" do
            it "returns true" do
              Timecop.freeze(Date.new(2020, 8, 19)) do
                # given
                kase = create_case(flagged: true,
                                   assignment_times: [30.business_days.ago, 25.business_days.ago, 8.business_days.ago])
                expect(kase).to be_flagged
                responder_assignments = kase.assignments.responding.order(:id)
                expect(responder_assignments.size).to eq 3
                expect(responder_assignments[0].state).to eq "rejected"
                expect(responder_assignments[1].state).to eq "rejected"
                expect(responder_assignments[2].state).to eq "accepted"

                expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 8.business_days.ago.to_date
                expect(kase.transitions.where(event: "add_responses")).to be_empty

                # then
                expect(kase.business_unit_already_late?).to be false
              end
            end
          end
        end

        context "late" do
          context "non trigger cases" do
            it "returns true" do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [30.business_days.ago, 25.business_days.ago, 21.business_days.ago])
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq "rejected"
              expect(responder_assignments[1].state).to eq "rejected"
              expect(responder_assignments[2].state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 21.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses")).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end

          context "trigger cases" do
            it "returns true" do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [30.business_days.ago, 25.business_days.ago, 11.business_days.ago])
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq "rejected"
              expect(responder_assignments[1].state).to eq "rejected"
              expect(responder_assignments[2].state).to eq "accepted"

              expect(kase.transitions.where(event: "accept_responder_assignment").first.created_at.to_date).to eq 11.business_days.ago.to_date
              expect(kase.transitions.where(event: "add_responses")).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end
        end
      end
    end
  end

  # creates a case with responder assignments and/or rejections
  #
  # * flagged: true if a trigger case is to be created, otherwise false
  # * assignment_times: an array of times when the case was assigned to a responding team.
  #                     All but the last will be rejected 15 minutes later.  The last assingment
  #                     in the array will be accepted
  # * responded_time: The time when the kase was responded
  #
  def create_case(flagged:, assignment_times:, responded_time: nil)
    creation_time = assignment_times.first
    acceptance_time = assignment_times.last + 15.minutes
    kase = nil
    Timecop.freeze(creation_time) do
      kase = flagged ? create_flagged_case : create_unflagged_case
      create_responder_assignments(kase:, assignment_times:)
      create_responder_acceptance(kase: kase.reload, acceptance_time:)
      create_response(kase:, responded_time:) unless responded_time.nil?
    end
    kase.reload
  end

  def create_flagged_case
    create :case, :flagged, approving_team: find_or_create(:team_dacu_disclosure)
  end

  def create_unflagged_case
    create :case
  end

  def create_responder_assignments(kase:, assignment_times:)
    while assignment_times.any?
      assignment_time = assignment_times.shift
      Timecop.freeze assignment_time do
        responding_team = create :responding_team
        responder_service = CaseAssignResponderService.new(team: responding_team,
                                                           kase:,
                                                           role: "responding",
                                                           user: @manager)
        responder_service.call
        if assignment_times.any?
          Timecop.travel 15.minutes
          responder_service.assignment.case.reload
          responder_service.assignment.reject(responding_team.users.first, "XXX")
          kase.reload
        end
      end
    end
  end

  def create_responder_acceptance(kase:, acceptance_time:)
    Timecop.freeze(acceptance_time) do
      kase.reload
      assignment = kase.assignments.responding.last
      assignment.accept(assignment.team.users.first)
    end
  end

  def create_response(kase:, responded_time:)
    kase.reload

    Timecop.freeze(responded_time) do
      filenames = ["#{Rails.root}/spec/fixtures/test_file.txt"]
      if kase.flagged?
        respond_to_flagged_case(kase, filenames)
      else
        respond_to_unflagged_case(kase, filenames)
      end
      kase.reload
      Timecop.freeze(responded_time + 10.minutes) do
        kase.respond(kase.responder)
      end
    end
  end

  def respond_to_flagged_case(kase, filenames)
    approving_team = find_or_create :team_dacu_disclosure
    approver = approving_team.users.first
    responding_team = kase.responding_team
    responder = responding_team.users.first

    kase.state_machine.add_responses!(acting_user: responder,
                                      acting_team: responding_team,
                                      filenames:)
    kase.state_machine.accept_approver_assignment!(acting_user: approver, acting_team: approving_team)
    approver_assignment = kase.assignments.approving.where(team_id: approving_team.id).first
    approver_assignment.update!(state: "accepted", user_id: approver.id)
    kase.state_machine.approve!(acting_user: approver, acting_team: approving_team)
  end

  def respond_to_unflagged_case(kase, filenames)
    responding_team = kase.responding_team
    responder = responding_team.users.first
    kase.state_machine.add_responses!(acting_user: responder,
                                      acting_team: responding_team,
                                      filenames:,
                                      message: "DDDD")
  end
end
