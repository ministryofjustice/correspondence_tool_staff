require "rails_helper"

describe Case::FOI::Standard do
  describe 'name' do
    it { should validate_presence_of(:name) }
  end
  describe 'requester_type' do
    it { should validate_presence_of(:requester_type)  }

    it { should have_enum(:requester_type).
                  with_values(
                    [
                      'academic_business_charity',
                      'journalist',
                      'member_of_the_public',
                      'offender',
                      'solicitor',
                      'staff_judiciary',
                      'what_do_they_know'
                    ]
                  )
    }
  end

  describe 'delivery_method' do
    it { should validate_presence_of(:delivery_method) }

    it { should have_enum(:delivery_method).
                  with_values(
                    [
                      'sent_by_email',
                      'sent_by_post'
                    ]
                  )
    }
  end


  describe '#business_unit_responded_in_time?' do

    before(:each) do
      @manager = create :manager
    end
    context 'case not yet responded' do
      it 'raises' do
        assigned_case = create :assigned_case
        expect {
          assigned_case.business_unit_responded_in_time?
        }.to raise_error ArgumentError, "Cannot call #business_unit_responded_in_time? on a case without a response (Case #{assigned_case.number})"
      end
    end

    context 'case has been responded' do
      context 'just one assignment to a team' do
        context 'in time' do
          context 'flagged' do
            it 'returns true' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_response_to_flagged_case').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end
          context 'unflagged' do
            it 'returns true' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end
        end

        context 'late' do
          context 'flagged' do
            it 'returns false' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [14.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 14.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_response_to_flagged_case').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end

          context 'unflagged' do
            it 'returns false' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [15.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged

              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 15.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end

        end
      end


      context 'multiple assignments and rejections' do
        context 'in time' do
          context 'flagged' do
            it 'returns true' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [12.business_days.ago, 10.business_days.ago, 7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_response_to_flagged_case').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end

          context 'unflagged' do
            it 'returns true' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [12.business_days.ago, 10.business_days.ago, 7.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 7.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be true
            end
          end
        end

        context 'late' do
          context 'flagged' do
            it 'returns false' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [17.business_days.ago, 16.business_days.ago, 14.business_days.ago],
                                 responded_time: 1.business_days.ago)
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 14.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_response_to_flagged_case').last.created_at.to_date).to eq 1.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end

          context 'unflagged' do
            it 'returns false' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [17.business_days.ago, 16.business_days.ago, 15.business_days.ago],
                                 responded_time: 3.business_days.ago)
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 15.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses').last.created_at.to_date).to eq 3.business_days.ago.to_date

              # then
              expect(kase.business_unit_responded_in_time?).to be false
            end
          end

        end
      end
    end
  end


  describe '#business_unit_already_late?' do

    before(:each) do
      @manager = create :manager
    end

    context 'responded case' do
      it 'raises' do
        responded_kase = create :responded_case
        expect{
          responded_kase.business_unit_already_late?
        }.to raise_error ArgumentError, 'Cannot call #business_unit_already_late? on a case for which the response has been sent'
      end
    end

    context 'open cases' do
      context 'just one assignment to responding team' do
        context 'in time' do
          context 'non trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [18.business_days.ago])
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 18.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be false
            end
          end

          context 'trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [8.business_days.ago])
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 8.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be false
            end
          end
        end

        context 'late' do
          context 'non trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [21.business_days.ago])
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 21.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end

          context 'trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [11.business_days.ago])
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 1
              expect(responder_assignments.first.state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 11.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end
        end
      end

      context 'multiple assignments to responding teams' do
        context 'in time' do
          context 'non trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [30.business_days.ago, 25.business_days.ago, 18.business_days.ago])
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 18.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be false
            end
          end

          context 'trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [30.business_days.ago, 25.business_days.ago, 8.business_days.ago])
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 8.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be false
            end
          end
        end
        context 'late' do
          context 'non trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: false,
                                 assignment_times: [30.business_days.ago, 25.business_days.ago, 21.business_days.ago])
              expect(kase).not_to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 21.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

              # then
              expect(kase.business_unit_already_late?).to be true
            end
          end

          context 'trigger cases' do
            it 'returns true' do
              # given
              kase = create_case(flagged: true,
                                 assignment_times: [30.business_days.ago, 25.business_days.ago, 11.business_days.ago])
              expect(kase).to be_flagged
              responder_assignments = kase.assignments.responding.order(:id)
              expect(responder_assignments.size).to eq 3
              expect(responder_assignments[0].state).to eq 'rejected'
              expect(responder_assignments[1].state).to eq 'rejected'
              expect(responder_assignments[2].state).to eq 'accepted'

              expect(kase.transitions.where(event: 'accept_responder_assignment').first.created_at.to_date).to eq 11.business_days.ago.to_date
              expect(kase.transitions.where(event: 'add_responses')).to be_empty

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
      create_responder_assignments(kase: kase, assignment_times: assignment_times)
      create_responder_acceptance(kase: kase.reload, acceptance_time: acceptance_time)
      create_response(kase: kase, responded_time: responded_time) unless responded_time.nil?
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
                                                           kase: kase,
                                                           role: 'responding',
                                                           user: @manager)
        responder_service.call
        if assignment_times.any?
          Timecop.travel 15.minutes
          responder_service.assignment.reject(responding_team.users.first, 'XXX')
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
      filenames = [ "#{Rails.root}/spec/fixtures/test_file.txt" ]
      if kase.flagged?
        respond_to_flagged_case(kase, filenames)
      else
        respond_to_unflagged_case(kase, filenames)
      end
      kase.reload
      # if kase.flagged?
      #   kase.state_machine.add_response_to_flagged_case!(acting_user: responder,
      #                                                    acting_team: responding_team,
      #                                                    filenames: filenames)
      # else
      #   kase.state_machine.add_responses!(acting_user: responder,
      #                                     acting_team: responding_team,
      #                                     filenames: filenames,
      #                                     message: 'DDDD')
      # end
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

    kase.state_machine.add_response_to_flagged_case!(acting_user: responder,
                                                       acting_team: responding_team,
                                                       filenames: filenames)
    kase.state_machine.accept_approver_assignment!(acting_user: approver, acting_team: approving_team)
    approver_assignment = kase.assignments.approving.where(team_id: approving_team.id).first
    approver_assignment.update(state: 'accepted', user_id: approver.id)
    kase.state_machine.approve!(acting_user: approver, acting_team: approving_team)
  end

  def respond_to_unflagged_case(kase, filenames)
    responding_team = kase.responding_team
    responder = responding_team.users.first
    kase.state_machine.add_responses!(acting_user: responder,
                                      acting_team: responding_team,
                                      filenames: filenames,
                                      message: 'DDDD')
  end
end
