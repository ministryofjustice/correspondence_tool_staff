class Workflows::Conditionals
  def initialize(user:, kase:)
    @user = user
    @kase = kase
  end

  def remove_response
    if @kase.attachments.size == 0
      'drafting'
    else
      'awaiting_dispatch'
    end
  end

  def flagged_for_press
    if @kase.approving_teams.size > 1
      'pending_press_office_clearance'
    else
      'awaiting_dispatch'
    end
  end
end
