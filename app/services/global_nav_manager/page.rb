class GlobalNavManager
  class Page
    attr_reader :name, :path, :filters, :tabs

    def initialize(name, global_nav, attrs)
      @name = name
      @global_nav = global_nav
      @path = attrs[:path]
      @filters = attrs[:filter] ? [attrs[:filter]] : []

      @tabs = build_tabs attrs[:tabs]

      process_visibility attrs[:visibility]
    end

    def user
      @global_nav.user
    end

    def visible?
      @visible
    end

    def fullpath
      @fullpath ||= if @tabs.empty?
                      @path
                    else
                      tabs.first.fullpath
                    end
    end

    def finder
      @finder ||= CaseFinderService.new(@global_nav.user,
                                        @filters,
                                        @global_nav.request.query_parameters)
    end

    def cases
      @cases ||= finder.cases
    end

    def matches_path?(match_path)
      fullpath == match_path
    end

    private

    def build_tabs(tabs_settings)
      tabs_settings ||= []
      tabs_settings.map do |tab_name, tab_settings|
        Tab.new(tab_name, @global_nav, self, tab_settings)
      end .find_all do |tab|
        tab.visible?
      end
    end

    def process_visibility(visibility_settings)
      if visibility_settings.blank?
        @visible = true
      else
        user_teams = user.teams.pluck(:code)
        user_roles = user.team_roles.pluck(:role)
        if !visibility_settings.respond_to? :keys
          @visible = (user_teams & visibility_settings).any? ||
                     (user_roles & visibility_settings).any?
        else
          teams_or_roles = visibility_settings.keys.map(&:to_s)
          matching_teams_or_roles = (user_teams & teams_or_roles) +
                                    (user_roles & teams_or_roles)
          @visible = matching_teams_or_roles.any?
          @filters += matching_teams_or_roles.map do |team_or_role|
            visibility_settings[team_or_role].filter
          end
        end
      end
    end
  end
end
