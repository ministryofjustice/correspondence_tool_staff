require File.join(Rails.root, 'spec', 'support', 'find_or_create_strategy')
require 'timecop'

module CTS
  class DemoSetup

    include FactoryBot::Syntax::Methods

    def initialize(number)
      @real_time = Time.zone.now
      @number = number
      @cases = Case::Base.order(id: :desc).limit(number).to_a
      @managing_team = CTS::dacu_team
      @responding_teams = BusinessUnit.where(name: ['Legal Aid Agency', 'HR', 'HMCTS North East Regional Support Unit (RSU)'])
      @dacu_disclosure = BusinessUnit.dacu_disclosure
      @press_office = BusinessUnit.press_office
      @oldest_received_date = 35.days.ago
      @newest_received_date = 3.days.ago
      @min_days_to_add_response = 3
      @max_days_to_add_response = 35
      @min_days_to_approve = 2
      @max_days_to_approve = 5
    end


    def run
      @number.times do |iternum|
        Timecop.freeze(random_date_received) do
          puts "\n>>>>>> Time frozen to #{Time.zone.now} for case creation"
          begin
            kase = create_case(flagged: random_flagged)
            Timecop.freeze random_response_time do
              puts ">>>>>> Time frozen to #{Time.zone.now} for response"
              add_responses(kase)
              unless iternum % 5 == 0
                n = random_days_to_approve
                approve_case(kase, n) if kase.requires_clearance?
                x = random_days_to_approve + n
                close_case(kase, x) unless iternum % 10 == 0
              end
            end
          rescue => err
            puts ">>>>>> ERROR #{err.class} #{err.message} <<<< "
            puts "Unable to create that case"
            puts err.backtrace
          end
          # print_case(kase)
        end
      end
    end

    private

    def least_of(a, b)
      a < b ? a : b
    end

    def random_response_time
      least_of(@real_time, Time.zone.now + random_days_to_response.days)
    end

    def random_approval_time(delay_days)
      least_of(@real_time, Time.zone.now + delay_days.days)
    end

    def random_date_received
      rand(@oldest_received_date..@newest_received_date)
    end

    def random_days_to_response
      (@min_days_to_add_response..@max_days_to_add_response).to_a.sample
    end

    def random_days_to_approve
      (@min_days_to_approve..@max_days_to_approve).to_a.sample
    end

    def random_flagged
      # [ true, true, true, true, false, false, false, false, false, false, false ].sample
      true
    end

    def random_dacu_disclosure_team_member
      @dacu_disclosure.users.sample
    end

    def create_case(flagged:)
      puts ">>>>>>>>>>>>>> creating case received #{Date.today} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      responding_team = @responding_teams.sample
      responder = responding_team.users.sample
      if flagged
        kase = create :accepted_case, :flagged, managing_team: @managing_team, responding_team: responding_team, responder: responder, approving_team: @dacu_disclosure
      else
        kase = create :accepted_case, managing_team: @managing_team, responding_team: responding_team, responder: responder
      end
      puts ">>>>>> created case #{kase.id} flagged: #{flagged} received: #{kase.received_date} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      kase
    end

    def add_responses(kase)
      puts ">>>>>> adding responses to case #{kase.id} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      upload_group = Time.zone.now.strftime('%Y%m%d%H%M%S')
      kase.attachments << [ build_response(kase, upload_group, 1),  build_response(kase, upload_group, 2) ]
      if kase.requires_clearance?
        kase.state_machine.add_responses!(kase.responder, kase.responding_team, ['Demo_file_1.pdf', 'Demo_file_2.pdf'])
      end
    end

    def build_response(kase, upload_group, sequence)
      filename = "Demo_file_#{sequence}.pdf"
      CaseAttachment.new(
        type: 'response',
        key: "#{kase.id}/responses/#{filename}",
        upload_group: upload_group,
        user_id: kase.responder.id
      )
    end


    def approve_case(kase, delay_days)
      Timecop.freeze Time.zone.now + delay_days.days do
        puts ">>>>>> Time frozen to #{Time.zone.now} for approval"
        dacu_approver= random_dacu_disclosure_team_member
        assig = kase.approver_assignments.for_team(@dacu_disclosure).first
        kase.state_machine.accept_approver_assignment!(acting_user: dacu_approver, acting_team: @dacu_disclosure)
        assig.update!(user_id:  dacu_approver.id, state: 'accepted')
        assig = kase.approver_assignments.for_team(@dacu_disclosure).first
        kase.state_machine.approve!(dacu_approver, assig)
      end
    end

    def close_case(kase, delay_days)
      Timecop.freeze random_approval_time(delay_days) do
        puts ">>>>>> closing case #{kase.id} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
        kase.state_machine.respond!(acting_user: kase.responder, acting_team: kase.responding_team)
        granted = CaseClosure::Outcome.where(abbreviation: 'granted').first
        kase.update!(date_responded: Date.today, outcome_id: granted.id)
        kase.state_machine.close!(@managing_team.users.sample)
      end
    end

    def print_case(kase)
      ap kase
      puts ">>>>>>>>>>>>>> attachmnents #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      ap kase.attachments
      puts ">>>>>>>>>>>>>> managing team #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      ap kase.managing_team
      puts ">>>>>>>>>>>>>> responding team #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      ap kase.responding_team
      puts ">>>>>>>>>>>>>> approving teams #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      ap kase.approving_teams
      puts ">>>>>>>>>>>>>> assignments #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      ap kase.assignments
      puts ">>>>>>>>>>>>>> transitions #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
      ap kase.transitions

    end
  end
end
