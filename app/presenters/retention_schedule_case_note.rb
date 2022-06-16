class RetentionScheduleCaseNote
  attr_accessor :kase, :user, :changes

  class AttrChange
    attr_accessor :from, :to

    def initialize(changes)
      @from, @to = changes.dig(self.class::ATTR_NAME)
    end

    def blank?
      @from.blank? && @to.blank?
    end

    def to_s
      I18n.t(
        self.class::ATTR_NAME, scope: scope, from: from, to: to
      ) unless blank?
    end

    def scope
      [:retention_schedule_case_notes, :changes]
    end
  end

  class StateChange < AttrChange
    ATTR_NAME = :state

    def from; I18n.t(@from, scope: 'dictionary.retention_schedule_states'); end
    def to; I18n.t(@to, scope: 'dictionary.retention_schedule_states'); end
  end

  class DateChange < AttrChange
    ATTR_NAME = :planned_destruction_date

    def from; I18n.l(@from, format: :compact); end
    def to; I18n.l(@to, format: :compact); end
  end

  def initialize(kase:, user:, changes:)
    @kase = kase
    @user = user
    @changes = changes

    add_note_to_case!
  end
  private_class_method :new

  def self.log!(**args)
    new(args)
  end

  private

  def add_note_to_case!
    return if changes.empty?

    @kase.state_machine.add_note_to_case!(
      acting_user: @user,
      acting_team: @user.case_team(@kase),
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
end
