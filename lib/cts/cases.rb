module CTS
  class Cases < Thor
    include Thor::Rails unless SKIP_RAILS

    CASE_JOURNEYS = {
      unflagged: [
        :awaiting_responder,
        :drafting,
        :awaiting_dispatch,
        :responded,
        :closed,
      ],
      flagged_for_dacu_disclosure: [
        :awaiting_responder,
        :accepted_by_dacu_disclosure,
        :drafting,
        :pending_dacu_disclosure_clearance,
        :awaiting_dispatch,
        :responded,
        :closed,
      ],
      flagged_for_press_office: [
        :awaiting_responder,
        :taken_on_by_press_office,
        :accepted_by_dacu_disclosure,
        :drafting,
      ]
    }

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
      Case.all.map(&:destroy)
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

    desc 'create OPTIONS all|<states>', 'Create cases in the specified states'
    long_desc <<~LONGDESC

    The create command takes the following sub commands:
     - all:        Create a number of cases in all states
     - <states>:   Create a number of cases in the specified state(s)

    Multiple states can be specified.

    Valid case journeys and their states:
    #{CASE_JOURNEYS.map do |j, states|
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
    option :clear, aliases: :x, type: :boolean,
           desc: 'Clear existing cases before creating.'
    option :dry_run, type: :boolean,
           desc: 'Print out what states cases will be created in.'
    option :responder, aliases: :r, type: :string,
           desc: 'ID or name of responder to use for case assignments.'
    option :responding_team, aliases: :t, type: :string,
           desc: 'ID or name of responding team to use for case assignments.'
    option :created_at, type: :string
    def create(*args)
      cmd = CTS::Cases::Create.new(self, options, args)
      cmd.call
    end

    desc 'list', 'List cases in the system.'
    def list
      columns = [
        :id,
        :number,
        :subject,
        :current_state,
        :requires_clearance?
      ]
      tp Case.all, columns
    end

    desc 'show', 'Show case details.'
    def show(*args)
      args.each do |case_identifier|
        kase = CTS::find_case(case_identifier)
        ap kase

        puts "\nAssignments:"
        team_display = team_display_method { |a| a.team }
        team_width = kase.assignments.map(&team_display).map(&:length).max
        user_display = user_display_method { |a| a.user }
        user_width = kase.assignments.map(&user_display).map(&:length).max
        tp kase.assignments, :id, :state, :role,
           { user: { display_method: user_display, width: user_width } },
           { team: { display_method: team_display, width: team_width } }

        puts "\nTransitions:"
        tp kase.transitions, :id, :event, :to_state, :user_id,
           metadata: { width: 60 }

        puts "\nAttachments:"
        tp kase.attachments, [:id, :type, :key, :preview_key]
      end
    end

    private

    def user_display_method(&get_user)
      lambda do |o|
        user = get_user.call o
        if user
          "#{user&.full_name}:#{user&.id}"
        else
          ''
        end
      end
    end

    def team_display_method(&get_team)
      lambda do |object|
        team = get_team.call object
        if team
          "#{team&.name}:#{team&.id}"
        else
          ''
        end
      end
    end
  end
end
