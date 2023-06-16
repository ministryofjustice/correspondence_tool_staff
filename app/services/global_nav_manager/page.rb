class GlobalNavManager
  class Page
    attr_reader :name, :path, :tabs

    IGNORE_QUERY_PARAMS = %w[page].freeze

    # 'parent' here is actually a GlobalNavManager instance
    def initialize(name:, parent:, attrs:)
      @name = name
      @parent = parent
      @path = attrs[:path]

      process_scope attrs[:scope] if attrs[:scope].present?

      @tabs = build_tabs attrs[:tabs]

      process_visibility attrs[:visibility]
    end

    def user
      @parent.user
    end

    def visible?
      @visible
    end

    def fullpath
      @fullpath ||= if @tabs.empty?
                      @path
                    else
                      @tabs.first.fullpath
                    end
    end

    def fullpath_with_query
      if @fullpath_with_query.nil?
        @fullpath_with_query = fullpath
        query_params = request.query_parameters.reject do |k, _|
          k.in? IGNORE_QUERY_PARAMS
        end
        if query_params.present?
          @fullpath_with_query += "?#{query_params.to_query}"
        end
      end
      @fullpath_with_query
    end

    def finder
      @parent.finder.for_scopes(@scope_names)
    end

    def cases
      @cases ||= finder.scope
    end

    def matches_path?(match_path)
      normalized_match_path = match_path.sub(".csv", "")
      fullpath == normalized_match_path
    end

    def request
      @parent.request
    end

  private

    # This 'method' is tested, so only exists for that reason
    attr_reader :scope_names

    def build_tabs(tabs_settings)
      tabs_settings ||= []
      tabs_settings.map { |tab_name, tab_settings|
        Tab.new(name: tab_name, parent: self, attrs: tab_settings)
      }.find_all(&:visible?)
    end

    def user_teams
      @user_teams ||= user.teams.pluck(:code)
    end

    def user_roles
      @user_roles ||= user.team_roles.pluck(:role)
    end

    def process_visibility(visibility)
      if visibility.blank?
        @visible = true
      else
        visibility = Array(visibility)
        @visible = (user_teams & visibility).any? ||
          (user_roles & visibility).any?
      end
    end

    def process_scope(scope)
      @scope_names = if scope.respond_to? :keys
                       (
                         scopes_for(user_teams, from_scope: scope.to_h.with_indifferent_access) +
                         scopes_for(user_roles, from_scope: scope.to_h.with_indifferent_access)
                       ).uniq
                     else
                       [scope]
                     end
    end

    def scopes_for(user_teams_or_roles, from_scope:)
      user_teams_or_roles.map { |user_team_or_role|
        if from_scope.key? user_team_or_role
          from_scope[user_team_or_role]
        end
      }.compact.uniq
    end
  end
end
