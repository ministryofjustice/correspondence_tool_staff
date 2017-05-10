require 'thor'
require 'thor/rails'


class CaseSeeder < Thor

  include Thor::Rails

  VALID_STATES = %w( unassigned awaiting_responder drafting awaiting_dispatch responded closed )

  desc "clear", "Delete all cases in the database"
  def clear
    check_environment
    puts "Deleting all cases"
    Case.all.map(&:destroy)
  end

  desc 'create', 'Create cases'
  long_desc <<~LONGDESC
    The create command takes the following sub commands:
      \x5 - all:        Create a number of cases in all states
      \x5 - <states>:   Create a number of cases in the specified state(s)

      Multiple states can be specified.

      Valid states are as follows:
           \x5 unassigned
           \x5 awaiting_responder
           \x5 drafting
           \x5 awaiting_dispatch
           \x5 responded
           \x5 closed

      The following switches can be specified
      \x5 -n<number>    Create <number> cases in each state (default 2)
      \x5 -d            Create cases which require DACU disclosure
      \x5 -x            Clear all existing cases before creating

      e.g.
      \x5./cts create unassigned drafting -n3 -d
      \x5./cts create all -x
    LONGDESC
  def create(*args)
    @states = []
    @number_to_create = 2
    @add_dacu_disclosure = false
    @invalid_params = false
    @clear_cases = false

    check_environment
    validate_teams_and_users_populated
    parse_params(args)
    clear if @clear_cases
    @states.each do |state|
      __send__("create_#{state}".to_sym)
    end
  end

  private

  def validate_teams_and_users_populated
    validate_teams_populated
    validate_users_populated
  end

  def validate_teams_populated
    teams = Team.where(name: ['DACU', 'DACU Disclosure', 'Legal Aid Agency', 'HR', 'HMCTS North East Response Unit(RSU)']).order(:name)
    if teams.size != 5
      puts "ERROR: Not all teams have been populated!"
      puts "Run 'rake db:seed:dev:users' to populate teams and users"
      exit 2
    end
    @dacu_team, @disclosure_team, @hmcts_team, @hr_team, @laa_team  = teams
  end

  def validate_users_populated
    @dacu_manager = @dacu_team.manager_user_roles.first.user
    @disclosure_approver = @disclosure_team.approver_user_roles.first.user
    @hmcts_responder = @hmcts_team.responder_user_roles.first.user

    if [@dacu_manager, @disclosure_approver, @hmcts_responder].any? { |u| u.nil? }
      puts "ERROR: Not all users have been populated!"
      puts "Run 'rake db:seed:dev:users' to populate teams and users"
      exit 3
    end
  end

  def create_unassigned
    create_unassigned_cases(@number_to_create)
  end

  def create_awaiting_responder
    cases = create_unassigned_cases(@number_to_create)
    cases.each do |kase|
      kase.responding_team = @hmcts_team
      kase.assign_responder(@dacu_manager, @hmcts_team)
    end
    cases
  end

  def create_drafting
    cases = create_awaiting_responder
    cases.each do |kase|
      kase.responder_assignment.update_attribute(:user, @hmcts_responder)
      kase.responder_assignment_accepted(@hmcts_responder, @hmcts_team)
    end
    cases
  end

  def create_awaiting_dispatch
    cases = create_drafting
    cases.each do |kase|
      ResponseUploaderService.new(kase, @hmcts_responder, nil).seed!
      kase.add_responses(@hmcts_responder, kase.attachments)
    end
    cases
  end

  def create_responded
    cases = create_awaiting_dispatch
    cases.each { |kase| kase.respond(@hmcts_responder) }
  end

  def create_closed
    cases = create_responded
    cases.each do |kase|
      kase.prepare_for_close
      kase.update(date_responded: Date.today, outcome_name: 'Granted in full')
      kase.close(@dacu_manager)
    end
  end

  def create_unassigned_cases(n)
    cases = []
    n.times do
      cases << FactoryGirl.create(:case, name: Faker::Name.name, subject: Faker::Company.catch_phrase, message: Faker::Lorem.paragraph, managing_team: @dacu_team)
    end
    cases
  end

  def assign_case_to_responding_team(kase, responding_team)
    kase.responding_team = responding_team
    kase.save!
  end



  def check_environment
    raise "Run cts in development rails environement only!" unless ::Rails.env.development?
  end

  def parse_params(args)


    args.each { |arg| process_arg(arg) }

    if @invalid_params
      puts "Program terminating"
      exit 1
    end
  end

  def process_arg(arg)
    if arg == 'all'
      @states = VALID_STATES
    elsif arg == '-d'
      @add_dacu_disclosure = true
    elsif arg =~ /-n([1-9])/
      @number_to_create = $1.to_i
    elsif arg == '-x'
      @clear_cases = true
    elsif arg.in?(VALID_STATES)
      @states << arg
    else
      puts "Unrecognised parameter: #{arg}"
      @invalid_params = true
    end
  end

end
