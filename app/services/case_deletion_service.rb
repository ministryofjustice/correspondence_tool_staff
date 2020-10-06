class CaseDeletionService
  attr_reader :result

  def initialize(user, kase, update_parameters)
    @user = user
    @kase = kase
    @update_parameters = update_parameters
    @result = :incomplete
  end

  def call
    if @kase.related_case_links.present?
      @kase.errors.add(:related_case_links, 
                        I18n.t('activerecord.errors.models.case.attributes.related_case_links.not_empty'))
      @result = :error
    elsif @kase.update(@update_parameters.merge(deleted: true))
      @kase.state_machine.destroy_case!(acting_user: @user, acting_team: @kase.managing_team)
      @result = :ok
    else
      @result = :error
    end

    @result
  end
end
