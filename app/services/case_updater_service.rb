class CaseUpdaterService
  attr_reader :result, :error_message

  def initialize(user, kase, params)
    @user = user
    @team = kase.managing_team
    @kase = kase
    @params = params
    @result = :incomplete
    @error_message = nil
    @old_rejected_reasons = kase.rejected_reasons
  end

  def call(message = nil)
    ActiveRecord::Base.transaction do
      # There is extra checking for linked cases as those changes won't appear in the
      # case's changed_attributes, has to be checked separately
      linked_cases_changed = have_linked_cases_changed?
      @kase.assign_attributes(@params)
      # properties is JSON object, if one of keys was not included
      # but later this key with value of nil is added,
      # it will be treated as changed which will give a misleading message
      # as from user's point of view, he/she doesn't change anything
      # Each key within this JSON object will be tracked individually,
      # no need for tracking properties as the whole.
      if (@kase.changed_attributes.keys - %w[properties]).present? || linked_cases_changed
        @kase.save # rubocop:disable Rails/SaveBang
        @kase.state_machine.edit_case!(acting_user: @user, acting_team: @team, message: log_message_for_rejected_reasons)
        @result = :ok
      else
        @result = :no_changes
      end
    end
  rescue StandardError => e
    @error_message = e.message
    @result = :error
  end

private

  def log_message_for_rejected_reasons
    if @old_rejected_reasons != @kase.rejected_reasons
      "<br><strong>Information outstanding:</strong><br>#{@kase.rejected_reasons.map { |reason|
        Case::SAR::Offender::REJECTED_REASONS[reason]
      }.append(@kase.other_rejected_reason).compact.join('<br>')}"
    else
      ""
    end
  end

  def have_linked_cases_changed?
    have_original_case_changed? || have_related_cases_changed?
  end

  def have_original_case_changed?
    (@kase.respond_to? :original_case_ids) &&
      @params[:original_case_ids].present? &&
      !two_arrays_are_equal?(@kase.original_case_ids, @params[:original_case_ids])
  end

  def have_related_cases_changed?
    (@kase.respond_to? :related_case_ids) &&
      @params[:related_case_ids].present? &&
      !two_arrays_are_equal?(@kase.related_case_ids, @params[:related_case_ids])
  end

  def two_arrays_are_equal?(array1, array2)
    Set.new(array1.map(&:to_s)) == Set.new(array2.map(&:to_s))
  end
end
