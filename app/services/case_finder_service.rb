class CaseFinderService
  attr_reader :user, :scope

  # Initialize with Pundit.policy_scope so scope always limited by what user is allowed to see
  def initialize(user)
    @user = user
    @scope = Pundit.policy_scope(@user, Case::Base.all)
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

  private

  def index_cases_scope
    # effectively a nop; just return all the cases the user can view
    scope
  end

  def closed_cases_scope
    closed_scope = scope.presented_as_closed
    if user.responder_only?
      case_ids = Assignment.with_teams(user.responding_teams).pluck(:case_id)
      closed_scope.where(id: case_ids).most_recent_first
    else
      closed_scope.most_recent_first
    end
  end

  def incoming_approving_cases_scope
    # NB: This scope has the potential to return duplicate cases when there's
    # multiple approver assignments. Given that that's not meant to happen in
    # production, so far as we know, I'm leaving off any 'uniq' constraint to
    # surface miss-configuration in tests.
    scope
      .flagged_for_approval(*user.approving_team)
      .unaccepted.by_deadline
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
    open_scope = scope.presented_as_open
      .joins(:assignments)
      .where(assignments: { state: ['pending', 'accepted']})
      .distinct('case.id')
    if user.responder_only?
      case_ids = Assignment.with_teams(user.responding_teams).pluck(:case_id)
      open_scope.where(id: case_ids)
    else
      open_scope
    end
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

  def new_cases_from_last_3_days(team)
    case_types_only_visible_with_further_clearance = [
      'Case::FOI::ComplianceReview',
      'Case::FOI::TimelinessReview'
    ]
    scope
      .joins(:transitions)
      .where.not(type: case_types_only_visible_with_further_clearance)
      .where("(properties ->> 'escalation_deadline')::date >= ?", Date.today)
      .or(
        scope
          .joins(:transitions)
          .where(type: case_types_only_visible_with_further_clearance)
          .where("(properties ->> 'escalation_deadline')::date >= ?", Date.today)
          .where('case_transitions.event = ?', :request_further_clearance)
      )
      .not_with_teams(team)
      .order(created_at: :desc)
      .distinct('case.id')
  end
end
