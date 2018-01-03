require 'cts'
require 'cts/cases/create'

module CTS::Cases
  class CLI < Thor
    # include Thor::Rails unless const_defined?(:SKIP_RAILS) && SKIP_RAILS

    default_command :list

    desc 'assign CASE TEAM [USER]', 'Assign a case a user'
    def assign(*args)
      case_id_or_number = args.shift
      if case_id_or_number.blank?
        error 'case not provided'
        help
        exit 1
      end
      team_id_or_name = args.shift
      if team_id_or_name.blank?
        error 'team not provided'
        help
        exit 1
      end
      user_id_or_name = args.shift

      kase = CTS::find_case(case_id_or_number)
      team = CTS::find_team(team_id_or_name)
      if user_id_or_name.present?
        user = CTS::find_user(user_id_or_name)
        role = team.user_roles.find_by(user: user).role
      else
        user = team.users.first
        role = { 'responder' => 'responding',
                 'manager'   => 'managing',
                 'approver'  => 'approving' }[team.user_roles.first.role]
      end


      assign_command = Cases::Assign.new(kase, user, team, role)
      assign_command.call
    end

    desc "clear", "Delete all cases in the database"
    def clear
      CTS::check_environment
      puts "Deleting all cases"
      Case::Base.all.map(&:destroy)
    end

    desc 'demo', 'Create a demo set of cases for stats reporting purposes'
    option :number, aliases: 'n', type: :numeric,
           desc: 'Number of cases to create (per state). [1]'
    def demo
      parse_options
      CTS::check_environment
      require File.join(File.dirname(__FILE__), '/demo_setup')
      CTS::DemoSetup.new(@number_to_create).run
    end

    desc 'check', 'Check cases for common development issues.'
    option :full_trace, aliases: 'T', type: :boolean,
           desc: 'Include full trace on error, not just project files.'
    option :trace, aliases: 't', type: :boolean,
           desc: 'Include trace exert on error, only including project files.'
    def check(*args)
      args.each do |kase_id_or_number|
        CTS::Cases::Check.new(kase_id_or_number, options).call
      end
    end

    desc 'create OPTIONS all|<states>', 'Create cases in the specified states'
    long_desc <<~LONGDESC

    The create command takes the following sub commands:
     - all:        Create a number of cases in all states
     - <states>:   Create a number of cases in the specified state(s)

    Multiple states can be specified.

    Valid case journeys and their states:
    #{CTS::Cases::Create::CASE_JOURNEYS.map do |j, states|
      ["    #{j}:\n",
       states.map { |s| "      #{s}\n" }]
    end .flatten.join}

    Examples:
      # Create a case in the drafting state with the given created-at time.
      ./cts cases create --created-at='2017-06-20 09:36:00' drafting

      # Create 2 cases in all states for the unflagged journey, clearing
      # existing cases from the DB first.
      ./cts cases create -x -n2 all

      # Display steps that would be taken to create a case flagged for DACU
      # Disclosure and in the "awaiting_responder" state.
      ./cts cases create --dry-run -f awaiting_responder

      # Create a case in the "awaiting_responder" state and flagged form
      # Press Office.
      ./cts cases create --flag-for-team=press drafting
    LONGDESC
    option :number, aliases: 'n', type: :numeric,
           desc: 'Number of cases to create (per state). [1]'
    option :flag_for_disclosure, aliases: :f, type: :boolean,
           desc: 'Flag case for DACU disclosure clearance.'
    option :flag_for_team, aliases: :F, type: :string,
           enum: %w{disclosure press private},
           desc: 'Flag case for specific clearance team.'
    option :dry_run, type: :boolean,
           desc: 'Print out what states cases will be created in.'
    option :force, type: :boolean,
           desc: 'Force creation of cases even if in prod environment.'
    option :responder, aliases: :r, type: :string,
           desc: 'ID or name of responder to use for case assignments.'
    option :responding_team, aliases: :t, type: :string,
           desc: 'ID or name of responding team to use for case assignments.'
    option :created_at, type: :string
    option :received_date, type: :string
    #rubocop:disable Metrics/CyclomaticComplexity
    def create(*target_states)
      creator = CTS::Cases::Create.new(CTS, options)

      puts "Creating #{options[:number]} cases in each of the following states:"
      puts "\t" + target_states.join("\n\t")
      if options.key? :responder
        puts "Setting responder user to: #{options[:responder]}"
      end
      if options.key? :responding_team
        puts "Setting responding team to: #{options[:responding_team]}"
      end
      if options[:flag_for_disclosure]
        puts 'Flagging each for DACU Disclosure clearance'
      end
      if options[:flag_for_team] == 'press'
        puts 'Flagging each for Press Office clearance'
      end
      if options[:flag_for_team] == 'private'
        puts 'Flagging each for Private Office clearance'
      end
      if options.key? :created_at
        puts "Setting created at to: #{options[:created_at]}"
      end
      if options.key? :received_date
        puts "Setting received date to: #{options[:received_date]}"
      end
      puts "\n"

      cases = creator.call(target_states)
      unless options[:dry_run]
        tp cases, [:id, :number, :current_state, :requires_clearance?]
      end
    end
    #rubocop:enable Metrics/CyclomaticComplexity

    desc 'list', 'List cases in the system.'
    long_desc <<~LONGDESC

    Examples:
      # List cases assigned to Dasha Diss
      ./cts cases list --assigned-user='Dasha Diss'

      # List cases assigned to Press Office
      ./cts cases list --assigned-team=/press/

      # List cases assigned to HR
      ./cts cases list -t /hr/

    LONGDESC
    option :assigned_user, aliases: :u, type: :array,
           desc: 'List cases assigned to user, identified by name or id.'
    option :assigned_team, aliases: :t, type: :array,
           desc: 'List cases assigned to team, identified by name or id.'
    def list
      cases = Case::Base.all
      if options[:assigned_user]
        users = options[:assigned_user].map { |u| CTS::find_user(u) }
        cases = cases.includes(:assignments)
                  .where(assignments: { user: users })
      end
      options.fetch(:assigned_team, []).each do |team_name|
        cases = cases.includes(:assignments)
                  .where(assignments: { team: CTS::find_teams(team_name) })
      end

      columns = [
        :id,
        :number,
        { subject: { width: 40 } },
        { current_state: {} },
        { responding_team: {
            display_method: ->(c) { c.responding_team&.name }
          } },
        { flagged?: {
            display_method: lambda do |kase|
              flags = []
              flags << 'dacu' if kase.with_teams?(CTS::dacu_disclosure_team)
              flags << 'press' if kase.with_teams?(CTS::press_office_team)
              flags.join(',')
            end
          }
        }
      ]
      tp cases.order(:id), columns
    end

    desc 'permitted_events CASE USER',
         'Show permitted events on case for a user.'
    def permitted_events(case_id_or_number, user_id_or_name)
      kase = CTS::find_case(case_id_or_number)
      user = CTS::find_user(user_id_or_name)
      permitted_events = kase.state_machine.permitted_events(user.id)
      puts "Permitted events:"
      tp permitted_events,
         [
           { event:      { display_method: ->(e) { e.to_s }, width: 40 } },
           { from_state: { display_method: ->(_) { kase.current_state } } },
           { to_state:   { display_method: ->(e) do
                                             kase.state_machine
                                               .next_state_for_event(
                                                 e,
                                                 user_id: user.id
                                               )
                                           end } }
         ]
    end

    desc 'show', 'Show case details.'
    def show(*args)
      args.each do |case_identifier|
        kase = CTS::find_case(case_identifier)
        ap kase

        puts "\nAssignments:"
        show_case_assignments(kase)

        puts "\nTransitions:"
        show_case_transitions(kase)

        puts "\nAttachments:"
        tp kase.attachments, [:id, :type, :key, :preview_key]
      end
    end

    private

    def show_case_assignments(kase)
      team_display = team_display_method :team
      team_width = kase.assignments.map(&team_display).map(&:length).max
      user_display = user_display_method :user
      user_width = kase.assignments.map(&user_display).map(&:length).max
      tp kase.assignments, :id, :state, :role,
         { user: { display_method: user_display, width: user_width } },
         { team: { display_method: team_display, width: team_width } }
    end

    def show_case_transitions(kase)
      transition_display_fields =
        [
          [:acting_team, team_display_method(:acting_team)],
          [:acting_user, user_display_method(:acting_user)],
          # [:target_team, team_display_method(:target_team)],
          # [:target_user, user_display_method(:target_user)],
        ].map do |field, display_method|
          max_width = longest_field(kase.transitions, &display_method)
          {
            field => {
              display_method: display_method,
              width: max_width
            }
          }
        end
      tp kase.transitions.order(:id),
         :id,
         :event,
         :to_state,
         transition_display_fields
    end

    def longest_field(objects, &display_method)
      objects.map(&display_method).map(&:length).max
    end

    def user_display_method(attr)
      lambda do |o|
        user = o.send attr
        if user
          "#{user&.full_name}:#{user&.id}"
        else
          ''
        end
      end
    end

    def team_display_method(attr)
      lambda do |object|
        team = object.send attr
        if team
          "#{team&.name}:#{team&.id}"
        else
          ''
        end
      end
    end
  end
end
