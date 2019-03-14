# This service takes a collection of users, and calculates the number of active cases for each user,
# returning the result through the #case_counts_by_user method.
#
class UserActiveCaseCountService

  def initialize
    @case_counts_by_user = {}
  end

  def case_counts_by_user(users)
    users.each { |user| get_counts_for_user(user) }
    @case_counts_by_user
  end

  def active_cases_for_user(user)
    scopes = get_scopes_for_user(user)
    CaseFinderService.new(user).for_scopes(scopes).scope
  end

  private

  def get_counts_for_user(user)
    scopes = get_scopes_for_user(user)
    case_count = CaseFinderService.new(user).for_scopes(scopes).scope.size
    @case_counts_by_user[user.id] = case_count
  end

  def get_scopes_for_user(user)
    scopes = []
    user.roles.each do |role|
      scopes << Settings.global_navigation.pages.my_open_cases.scope.__send__(role)
    end
    scopes.compact
  end

end
