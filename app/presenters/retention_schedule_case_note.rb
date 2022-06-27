class RetentionScheduleCaseNote
  attr_accessor :kase, :user, :changes, :is_system

  class AttrChange
    attr_accessor :from, :to

    def initialize(changes)
      @from, @to = changes.dig(self.class::ATTR_NAME)
    end

    def blank?
      @from.blank? && @to.blank?
    end

    def to_s
      return if blank?

      if @from && @to
        I18n.t(
          self.class::ATTR_NAME, scope: scope_for_update, from: from, to: to
        )
      else
        I18n.t(
          self.class::ATTR_NAME, scope: scope_for_create, to: to
        )
      end
    end

    def scope_for_update
      [:retention_schedule_case_notes, :update]
    end

    def scope_for_create
      [:retention_schedule_case_notes, :create]
    end
  end

  class StateChange < AttrChange
    ATTR_NAME = :state

    def from; I18n.t(@from, scope: 'dictionary.retention_schedule_states'); end
    def to; I18n.t(@to, scope: 'dictionary.retention_schedule_states'); end

    # On creation, the state is always `Not set` and this has no interest
    # in the case history, so we skip the message (from `nil` to `not_set`)
    def blank?
      @from.blank?
    end
  end

  class DateChange < AttrChange
    ATTR_NAME = :planned_destruction_date

    def from; I18n.l(@from, format: :compact); end
    def to; I18n.l(@to, format: :compact); end
  end

  def initialize(kase:, user:, changes:, is_system: false)
    @kase = kase
    @user = user
    @changes = changes
    @is_system = is_system

    trigger_event!
  end
  private_class_method :new

  def self.log!(**args)
    new(args)
  end

  private

  def trigger_event!
    return if changes.empty?

    kase.state_machine.public_send(
      "#{event_name}!",
      acting_user: user,
      acting_team: user.case_team(kase),
      message: message
    )
  end

  def message
    state_change = StateChange.new(changes)
    date_change  = DateChange.new(changes)

    [
      state_change,
      date_change,
    ].compact_blank.join("\n")
  end

  def event_name
    if is_system
      CaseTransition::ANNOTATE_SYSTEM_RETENTION_CHANGES
    else
      CaseTransition::ANNOTATE_RETENTION_CHANGES
    end
  end
end
