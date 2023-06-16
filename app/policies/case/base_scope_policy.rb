class Case::BaseScopePolicy
  attr_reader :user, :scope, :feature

  def initialize(user, scope, feature = nil)
    @user  = user
    @scope = scope
    @feature = feature
  end

  def correspondence_type
    nil
  end

  def resolve
    if @user.permitted_correspondence_types.include? correspondence_type
      perform_resolve
    else
      resolve_default
    end
  end

  def perform_resolve
    scopes = []
    user.roles.each do |role|
      resolve_func_name = "resolve_#{role}_default"
      resolve_func_feature_name = "resolve_#{role}_#{@feature.present? ? @feature.to_s : 'default'}"
      if respond_to?(resolve_func_feature_name)
        scopes << send(resolve_func_feature_name)
      elsif respond_to?(resolve_func_name)
        scopes << send(resolve_func_name)
      end
    end
    if scopes.any?
      scopes.reduce { |memo, scope| memo.or(scope) }
    else
      resolve_default
    end
  end

  def resolve_default
    @scope.none
  end

  def resolve_responder_default
    @scope.where(id: Assignment.team_restriction(@user.id, :responder))
  end

  def resolve_manager_default
    @scope
  end

  def resolve_approver_default
    @scope.where(id: Assignment.team_restriction(@user.id, :approver))
  end

  def resolve_team_admin_default
    resolve_default
  end
end
