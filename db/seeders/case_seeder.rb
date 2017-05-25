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

  desc 'users', 'Lists users'
  def users
    users = User.order(:full_name)
    users.each do |u|
      puts sprintf("%10s %-30s", 'Id:', u.id)
      puts sprintf("%10s %-30s", 'Name:', u.full_name)
      puts sprintf("%10s %-30s", 'Email:', u.email)
      u.team_roles.each do |tr|
        puts sprintf("%10s %-30s", 'Team:', "#{tr.team.name} : #{tr.role}")
      end
      puts "  "
    end
  end

  desc 'create all|<states> [-n n] [-d] [-x]', 'Create <-n> cases in the specified states'
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
  option :n, type: :numeric
  option :d, type: :boolean
  option :x, type: :boolean
  def create(*args)
    @states = []
    @number_to_create = options[:n] || 2
    @add_dacu_disclosure = options[:d] || false
    @clear_cases = options[:x] || false
    @invalid_params = false

    check_environment
    validate_teams_and_users_populated
    parse_params(args)

    clear if @clear_cases

    puts "Creating #{@number_to_create} cases in each of the following states: #{@states.join(', ')}"
    puts "Flagging each for DACU disclosure" if @add_dacu_disclosure
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
    @dacu_team, @disclosure_team, @hmcts_team, @hr_team, @laa_team = ['DACU', 'DACU Disclosure', 'Legal Aid Agency', 'HR', 'HMCTS North East Response Unit(RSU)'].map do |team_name|
      teams = Team.where(name: team_name)
      if teams.count > 1
        log_error "ERROR: multiple entries found for team: #{team_name}"
        exit 2
      elsif teams.count == 0
        log_error "ERROR: team missing: #{team_name}"
        log_error "Run 'rake db:seed:dev:users' to populate teams and users"
        exit 2
      else
        teams.first
      end
    end
  end

  def validate_users_populated
    begin
      @dacu_manager = @dacu_team.managers.first ||
                      raise("DACU BMT missing users")
      @disclosure_approver = @disclosure_team.approvers.first ||
                             raise("DACU Disclosure missing users")
      @hmcts_responder = @hmcts_team.responders.first ||
                         raise("HMCTS missing users")
    rescue => ex
      log_error "Error validating users:"
      log_error ex.message
      log_error "Run 'rake db:seed:dev:users' to populate teams and users"
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
    cases.each do |kase|
      kase.respond(@hmcts_responder)
    end
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
      kase = FactoryGirl.create(:case,
                                name: Faker::Name.name,
                                subject: Faker::Company.catch_phrase,
                                message: Faker::Lorem.paragraph(10, true, 10),
                                managing_team: @dacu_team)
      flag_for_dacu_approval(kase)
      cases << kase
    end
    cases
  end

  def assign_case_to_responding_team(kase, responding_team)
    kase.responding_team = responding_team
    kase.save!
  end

  def flag_for_dacu_approval(kase)
    if @add_dacu_disclosure
      result = CaseFlagForClearanceService.new(user:@dacu_manager, kase:kase).call
      if result != :ok
        log_error "Could not flag case for clearance: #{kase}"
      end
    end
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
    elsif arg.in?(VALID_STATES)
      @states << arg
    else
      puts "Unrecognised parameter: #{arg}"
      @invalid_params = true
    end
  end

  def log_error(msg)
    puts "!!! #{msg}"
  end
end
