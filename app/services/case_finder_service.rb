class CaseFinderService
  attr_reader :user, :scope

  # Initialize with Pundit.policy_scope so scope always limited by what user is allowed to see
  def initialize(user)
    @user = user
    @scope = get_root_scope
  end

  def for_scopes scope_names
    # This takes a list of scope names:
    #
    #   ['open_cases', 'open_flagged_for_approval']
    #
    # And performs an AREL OR on them:
    #
    #   open_cases_scope.or(open_flagged_for_approval_scope)
    #
    # This will work with any number of *_scope methods that return an AREL.
    if scope_names.any?
      scopes = scope_names.map do |scope_name|
        scope_method = "#{scope_name}_scope"
        if respond_to? scope_method, true
          __send__ scope_method
        else
          raise NameError.new("could not find scope named #{scope_method}")
        end
      end

      @scope = scopes.reduce { |merged_scopes, scope| merged_scopes.or(scope) }
    end

    self
  end

  def for_params(params)
    if params['states'].present?
      @scope = in_states(params['states'])
    end
    self
  end

  def closed_cases_scope
    get_root_scope('closed_cases_scope').presented_as_closed
  end

  def retention_cases_scope
    get_root_scope('default')
      .includes(:retention_schedule)
      .where(retention_schedule: {
        planned_destruction_date: RetentionSchedule.common_date_viewable_from_range
      })
  end

  private

  def get_root_scope(feature = nil)
    if feature.present?
      Case::BasePolicy::Scope.new(user, Case::Base.all, feature).resolve
    else
      Pundit.policy_scope(@user, Case::Base.all)
    end
  end

  def index_cases_scope
    # effectively a nop; just return all the cases the user can view
    scope
  end

  def incoming_approving_cases_scope
    # NB: This scope has the potential to return duplicate cases when there's
    # multiple approver assignments. Given that that's not meant to happen in
    # production, so far as we know, I'm leaving off any 'uniq' constraint to
    # surface miss-configuration in tests.
    scope
      .flagged_for_approval(*user.approving_team)
      .unaccepted
      .opened
      .by_deadline
  end

  def incoming_cases_press_office_scope
    new_cases_from_last_3_days([BusinessUnit.press_office])
  end

  def incoming_cases_private_office_scope
    new_cases_from_last_3_days([BusinessUnit.private_office])
  end

  def my_open_cases_scope
    scope.joins(:assignments).presented_as_open
      .with_user(user)
      .distinct('case.id')
  end

  def my_open_flagged_for_approval_cases_scope
    scope.presented_as_open
      .flagged_for_approval(*user.approving_team)
      .with_user(user, states: ['accepted'])
      .distinct('case.id')
  end

  def open_cases_scope
    get_root_scope('open_cases_scope')
    .presented_as_open
    .joins(:assignments)
    .where(assignments: { state: ['pending', 'accepted']})
    .distinct('case.id')
  end

  def erasable_cases_scope
    retention_cases_scope.where(
      retention_schedule: { 
        state: [:to_be_destroyed]
      })
  end

  def triagable_cases_scope
    triagable_states = [:review, :retain, :not_set]
    retention_cases_scope.where(
      retention_schedule: { 
        state: triagable_states
      })
  end

  def open_flagged_for_approval_scope
    scope.presented_as_open
      .flagged_for_approval(*user.approving_team)
      .where(assignments: { state: ['accepted']})
      .distinct('case.id')
  end

  def in_time_cases_scope
    scope.in_time
  end

  def late_cases_scope
    scope.late
  end

  def in_states(states)
    scope.in_states(states.split(','))
  end

  CASE_TYPES_ONLY_VISIBLE_WITH_FURTHER_CLEARANCE = [
    Case::FOI::ComplianceReview,
    Case::FOI::TimelinessReview
  ].map(&:name)

  def new_cases_from_last_3_days(team)
    scope
      .joins(:transitions)
      .where.not(type: CASE_TYPES_ONLY_VISIBLE_WITH_FURTHER_CLEARANCE)
      .where("(properties ->> 'escalation_deadline')::date >= ?", Time.zone.today)
      .or(
        scope
          .joins(:transitions)
          .where(type: CASE_TYPES_ONLY_VISIBLE_WITH_FURTHER_CLEARANCE)
          .where("(properties ->> 'escalation_deadline')::date >= ?", Time.zone.today)
          .where(case_transitions: { event: :request_further_clearance })
      )
      .not_with_teams(team)
      .order(created_at: :desc)
      .distinct('case.id')
  end
end
