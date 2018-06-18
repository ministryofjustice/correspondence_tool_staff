class StandardSetup # rubocop:disable Metrics/ClassLength

  class << self
    extend FactoryBot::Syntax::Methods

    # Used because of some badly understood issue with Ruby class inheritance /
    # methods. The procs generated for the fixtures above require this
    # method_missing.
    def self.method_missing(method_name, *args)
      if @@user_teams&.key?(method_name)
        @@user_teams[method_name].call
      elsif @@users&.key?(method_name)
        @@users[method_name].call
      elsif @@cases&.key?(method_name)
        @@cases[method_name].call
      elsif @@teams&.key?(method_name)
        @@teams[method_name].call
      else
        super
      end
    end

    @@teams = {
      disclosure_bmt_team:    -> { find_or_create(:team_dacu) },
      disclosure_team:        -> { find_or_create(:team_dacu_disclosure) },
      responding_team:        -> { find_or_create(:responding_team, name: 'Main responding_team') },
      press_office_team:      -> { find_or_create(:team_press_office) },
      private_office_team:    -> { find_or_create(:team_private_office) },
      another_approving_team: -> { find_or_create(:approving_team, name: 'approving_team') },
    }

    @@users = {
      disclosure_bmt_user:                 -> { find_or_create(:disclosure_bmt_user,
                                                               :findable) },
      disclosure_specialist_user:          -> { find_or_create(:disclosure_specialist,
                                                               :findable) },
      disclosure_specialist_coworker_user: -> {
        find_or_create(:disclosure_specialist,
                       :findable,
                       identifier: 'coworker disclosure_specialist',
                       approving_team: disclosure_team)
      },

      another_disclosure_specialist_user:  -> {
        find_or_create(:disclosure_specialist,
                       :findable,
                       identifier: 'another_disclosure_specialist',
                       approving_team: another_approving_team,)
      },
      responder_user:                      -> { find_or_create(:responder,
                                                               :findable,
                                                               responding_teams:[responding_team]) },
      sar_responder_user:                  -> { find_or_create(:responder,
                                                               :findable,
                                                               responding_teams:[responding_team]) },
      another_responder_in_same_team_user: -> { find_or_create(:responder,
                                                               :findable,
                                                               identifier: 'another_responder_in_same_team',
                                                               responding_teams:[responding_team]) },
      another_responder_in_diff_team_user: -> { find_or_create(:responder,
                                                               :findable,
                                                               identifier: 'another_responder_in_diff_team') },
      press_officer_user:                  -> { find_or_create(:press_officer,
                                                               :findable) },
      private_officer_user:                -> { find_or_create(:private_officer,
                                                               :findable) },
    }

    @@user_teams = {
      disclosure_bmt:                 -> { [ disclosure_bmt_user, disclosure_bmt_team ] },
      disclosure_specialist:          -> { [ disclosure_specialist_user, disclosure_team ] },
      disclosure_specialist_coworker: -> { [ disclosure_specialist_coworker_user, disclosure_team] },
      another_disclosure_specialist:  -> { [ another_disclosure_specialist_user, another_approving_team ] },
      responder:                      -> { [ responder_user, responding_team ] },
      another_responder_in_same_team: -> { [ another_responder_in_same_team_user, responding_team ] },
      another_responder_in_diff_team: -> { [ another_responder_in_diff_team_user, another_responder_in_diff_team_user.responding_teams.first ] },
      press_officer:                  -> { [ press_officer_user, press_office_team ] },
      private_officer:                -> { [ private_officer_user, private_office_team ] },
    }

    # Each case is created in a lambda so that it can be conditionally created
    # depending on how StandardSetup is instantiated (see the only_cases arg). 
    @@cases = {
      sar_noff_unassigned: ->(attributes={}) {
        create(:sar_case,
               {identifier: 'sar_noff_unassigned'}
                 .merge(attributes))
      },
      sar_noff_awresp: ->(attributes={}) {
        create(:awaiting_responder_sar,
               {responding_team: responding_team,
                identifier: 'sar_noff_awresp'}
                 .merge(attributes))
      },
      sar_noff_draft: ->(attributes={}) {
        create(:sar_being_drafted,
               {responder: responder_user,
                identifier: 'sar_noff_draft'}
                 .merge(attributes))
      },
      sar_noff_closed: ->(attributes={}) {
        create(:closed_sar,
               {identifier: 'sar_noff_closed'}
                 .merge(attributes))
      },

      std_unassigned_foi: ->(attributes={}) {
        create(:case,
               {identifier: 'std_unassigned_foi'}
                 .merge(attributes))
      },
      std_awresp_foi: ->(attributes={}) {
        create(:assigned_case,
               {responding_team: responding_team,
                identifier: 'std_awresp_foi'}
                 .merge(attributes))
      },
      std_draft_foi: ->(attributes={}) {
        create(:accepted_case,
               {responder: responder_user,
                identifier: 'std_draft_foi'}
                 .merge(attributes))
      },
      std_draft_foi_late: ->(attributes={}) {
        create(:accepted_case,
               {responder: responder_user,
                received_date: 25.business_days.ago,
                identifier: 'std_draft_foi_late'}
                 .merge(attributes))
      },
      std_awdis_foi: ->(attributes={}) {
        create(:case_with_response,
               {responder: responder_user,
                identifier: 'std_awdis_foi'}
                 .merge(attributes))
      },
      std_responded_foi: ->(attributes={}) {
        create(:responded_case,
               {responder: responder_user,
                identifier: 'std_responded_foi'}
                 .merge(attributes))
      },
      std_responded_foi_late: ->(attributes={}) {
        create(:responded_case,
               {responder: responder_user,
                received_date: 25.business_days.ago,
                date_responded: 1.business_days.ago,
                identifier: 'std_responded_foi_late'}
                 .merge(attributes))
      },
      std_closed_foi: ->(attributes={}) {
        create(:closed_case,
               {identifier: 'std_closed_foi'}
                 .merge(attributes))
      },
      std_closed_foi_late: ->(attributes={}) {
        create(:closed_case,
               {received_date: 25.business_days.ago,
                date_responded: 1.business_days.ago,
                identifier: 'std_closed_foi_late'}
                 .merge(attributes))
      },
      trig_unassigned_foi_accepted: ->(attributes={}) {
        create(:case,
               :flagged_accepted,
               :dacu_disclosure,
               {approver: disclosure_specialist_user,
                identifier: 'trig_unassigned_foi_accepted'}
                 .merge(attributes))
      },
      trig_unassigned_foi: ->(attributes={}) {
        create(:case,
               :flagged,
               :dacu_disclosure,
               {identifier: 'trig_unassigned_foi'}
                 .merge(attributes))
      },
      trig_awresp_foi_accepted: ->(attributes={}) {
        create(:assigned_case,
               :flagged_accepted,
               :dacu_disclosure,
               {approver: disclosure_specialist_user,
                responding_team: responding_team,
                identifier: 'trig_awresp_foi_accepted'}
                 .merge(attributes))
      },
      trig_awresp_foi: ->(attributes={}) {
        create(:assigned_case,
               :flagged,
               :dacu_disclosure,
               {responding_team: responding_team,
                identifier: 'trig_awresp_foi'}
                 .merge(attributes))
      },
      trig_draft_foi_accepted: ->(attributes={}) {
        create(:accepted_case,
               :flagged_accepted,
               :dacu_disclosure,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                identifier: 'trig_draft_foi_accepted'}
                 .merge(attributes))
      },
      trig_draft_foi_accepted_late: ->(attributes={}) {
        create(:accepted_case,
               :flagged_accepted,
               :dacu_disclosure,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                received_date: 25.business_days.ago,
                identifier: 'trig_draft_foi_accepted_late'}
                 .merge(attributes))
      },
      trig_draft_foi: ->(attributes={}) {
        create(:accepted_case,
               :flagged,
               :dacu_disclosure,
               {responder: responder_user,
                identifier: 'trig_draft_foi'}
                 .merge(attributes))
      },
      trig_draft_foi_late: ->(attributes={}) {
        create(:accepted_case,
               :flagged,
               :dacu_disclosure,
               {responder: responder_user,
                received_date: 25.business_days.ago,
                identifier: 'trig_draft_foi_late'}
                 .merge(attributes))
      },
      trig_pdacu_foi_accepted: ->(attributes={}) {
        create(:pending_dacu_clearance_case,
               {approver: disclosure_specialist_user,
                responder: responder_user,
                identifier: 'trig_pdacu_foi_accepted'}
                 .merge(attributes))
      },
      trig_pdacu_foi: ->(attributes={}) {
        create(:unaccepted_pending_dacu_clearance_case,
               {responder: responder_user,
                identifier: 'trig_pdacu_foi'}
                 .merge(attributes))
      },
      trig_awdis_foi: ->(attributes={}) {
        create(:case_with_response,
               :flagged_accepted,
               :dacu_disclosure,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                identifier: 'trig_awdis_foi'}
                 .merge(attributes))
      },
      trig_responded_foi: ->(attributes={}) {
        create(:responded_case,
               :flagged_accepted,
               :dacu_disclosure,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                identifier: 'trig_responded_foi'}
                 .merge(attributes))
      },
      trig_closed_foi: ->(attributes={}) {
        create(:closed_case,
               :flagged_accepted,
               :dacu_disclosure,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                identifier: 'trig_closed_foi'}
                 .merge(attributes))
      },
      trig_closed_foi_late: ->(attributes={}) {
        create(:closed_case,
               :flagged_accepted,
               :dacu_disclosure,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                received_date: 25.business_days.ago,
                date_responded: 1.business_days.ago,
                identifier: 'trig_closed_foi_late'}
                 .merge(attributes))
      },
      full_unassigned_foi: ->(attributes={}) {
        create(:case,
               :flagged,
               :press_office,
               {responder: responder_user,
                identifier: 'full_unassigned_foi'}
                 .merge(attributes))
      },
      full_awresp_foi: ->(attributes={}) {
        create(:assigned_case,
               :flagged,
               :press_office,
               {responding_team: responding_team,
                identifier: 'full_awresp_foi'}
                 .merge(attributes))
      },
      full_awresp_foi_accepted: ->(attributes={}) {
        create(:assigned_case,
               :flagged_accepted,
               :press_office,
               {responding_team: responding_team,
                identifier: 'full_awresp_foi_accepted'}
                 .merge(attributes))
      },
      full_draft_foi: ->(attributes={}) {
        create(:accepted_case,
               :flagged,
               :press_office,
               {responder: responder_user,
                identifier: 'full_draft_foi'}
                 .merge(attributes))
      },
      full_pdacu_foi_accepted: ->(attributes={}) {
        create(:pending_dacu_clearance_case_flagged_for_press_and_private,
               {approver: disclosure_specialist_user,
                responder: responder_user,
                identifier: 'full_pdacu_foi_accepted'}
                 .merge(attributes))
      },
      full_pdacu_foi_unaccepted: ->(attributes={}) {
        create(:unaccepted_pending_dacu_clearance_case_flagged_for_press_and_private,
               {responder: responder_user,
                identifier: 'full_pdacu_foi_unaccepted'}
                 .merge(attributes))
      },
      full_ppress_foi: ->(attributes={}) {
        create(:pending_press_clearance_case,
               {approver: disclosure_specialist_user,
                responder: responder_user,
                identifier: 'full_ppress_foi'}
                 .merge(attributes))
      },
      full_ppress_foi_accepted: ->(attributes={}) {
        create(:pending_press_clearance_case,
               {approver: disclosure_specialist_user,
                press_officer: press_officer_user,
                private_officer: private_officer_user,
                responder: responder_user,
                identifier: 'full_ppress_foi_accepted'}
                 .merge(attributes))
      },
      full_pprivate_foi: ->(attributes={}) {
        create(:pending_private_clearance_case,
               {approver: disclosure_specialist_user,
                responder: responder_user,
                identifier: 'full_pprivate_foi'}
                 .merge(attributes))
      },
      full_pprivate_foi_accepted: ->(attributes={}) {
        create(:pending_private_clearance_case,
               {approver: disclosure_specialist_user,
                press_officer: press_officer_user,
                private_officer: private_officer_user,
                responder: responder_user,
                identifier: 'full_pprivate_foi_accepted'}
                 .merge(attributes))
      },
      full_awdis_foi: ->(attributes={}) {
        create(:case_with_response,
               :flagged_accepted,
               :press_office,
               {responder: responder_user,
                approver: disclosure_specialist_user,
                identifier: 'full_awdis_foi'}
                 .merge(attributes))
      },
      full_responded_foi: ->(attributes={}) {
        create(:responded_case,
               :flagged,
               :press_office,
               {responder: responder_user,
                identifier: 'full_responded_foi'}
                 .merge(attributes))
      },
      full_closed_foi: ->(attributes={}) {
        create(:closed_case,
               :flagged,
               :press_office,
               {identifier: 'full_closed_foi'}
                 .merge(attributes))
      },

      std_unassigned_irc: ->(attributes={}) {
        create(:compliance_review,
               {identifier: 'std_unassigned_irc'}
                 .merge(attributes))
      },
      std_closed_irc: ->(attributes={}) {
        create(:closed_compliance_review,
               {identifier: 'std_closed_irc'}
                 .merge(attributes))
      },

      std_unassigned_irt: ->(attributes={}) {
        create(:timeliness_review,
               {identifier: 'std_unassigned_irt'}
                 .merge(attributes))
      },
      std_draft_irt: ->(attributes={}) {
        create(:accepted_timeliness_review,
               {identifier: 'std_draft_irt'}
                 .merge(attributes))
      },
      std_closed_irt: ->(attributes={}) {
        create(:closed_timeliness_review,
               {identifier: 'std_closed_irt'}
                 .merge(attributes))
      }
    }

    # Used when not instantiating a StandardSetup object in a before block.
    # This will create a new fixture, using 'find_or_create' for teams and
    # users and 'create' for cases. This is used to have a standardised set of
    # users, teams and cases to work with, but without requiring
    # pre-instantiation.
    def method_missing(method_name, *args)
      if @@user_teams&.key?(method_name)
        @@user_teams[method_name].call
      elsif @@users&.key?(method_name)
        @@users[method_name].call
      elsif @@cases&.key?(method_name)
        @@cases[method_name].call
      elsif @@teams&.key?(method_name)
        @@teams[method_name].call
      else
        super
      end
    end
  end

  attr_reader :cases, :user_teams, :users

  def initialize(only_cases: nil)
    # cases are named <workflow>_<state>_<other_info> where:
    #
    # * workflow:
    #   * std - standard workflow
    #   * trig - trigger workflow
    #   * full = full_approval workflow
    #
    # * state
    #   * unassigned - unassigned
    #   * awdis       - awaiting_dispatch
    #   * awresp      - awaiting_responder
    #   * closed      - closed
    #   * draft       - drafting
    #   * pdacu       - pending_dacu_clearance
    #   * ppress      - pending_press_office_clearance
    #   * pprivate    - pending_private_office_clerance
    #   * responded   - responded
    #

    @teams = @@teams.transform_values { |team| team.call }
    @users = @@users.transform_values { |user| user.call }
    @user_teams = @@user_teams.transform_values { |user_team| user_team.call }

    if only_cases.respond_to? :keys
      @cases = @@cases.slice(*only_cases.keys)
      only_cases.each do |name, attrs|
        # instantiate case by calling the blocks in @@cases and passing in any
        # attributes defined in only_cases for this case.
        @cases[name] = @cases[name].call(attrs)
      end
    else
      case_types = only_cases || @@cases.keys
      @cases = @@cases.slice(*case_types).transform_values do |kase|
        # instantiate case by calling the blocks in @@cases
        kase.call
      end
    end
  end


  # Used when instantiating a StandardSetup object to pre-instantiate fixtures
  # in a before block (e.g. global_state_machine_spec.rb). This allows test to
  # run faster.
  def method_missing(method_name, *args)
    if @user_teams&.key?(method_name)
      @user_teams[method_name]
    elsif @users&.key?(method_name)
      @users[method_name]
    elsif @cases&.key?(method_name)
      @cases[method_name]
    elsif @teams&.key?(method_name)
      @teams[method_name]
    else
      super
    end
  end
end
