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

  def unflag_for_clearance
    if @user.disclosure_specialist?
      'standard'
    else
      if @kase.assignments.where(team_id: BusinessUnit.dacu_disclosure.id).any?
        'trigger'
        else
        'standard'
      end
    end
  end

  def transition_unflag_for_clearance
    if @user.disclosure_specialist?
      'awaiting_dispatch'
    else
      @kase.current_state
    end
  end

end
