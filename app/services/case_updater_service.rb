class CaseUpdaterService
  attr_reader :result, :error_message

  def initialize(user, kase, params)
    @user = user
    @team = kase.managing_team
    @kase = kase
    @params = params
    @result = :incomplete
    @error_message = nil
  end

  def call
    begin
      ActiveRecord::Base.transaction do
        # There is extra checking for linked cases as those changes won't appear in the 
        # case's changed_attributes, has to be checked separately
        linked_cases_changed = has_linked_cases_changed?
        @kase.assign_attributes(@params)
        # properties is JSON object, if one of keys was not included 
        # but later this key with value of nil is added, 
        # it will be treated as changed which will give a misleading message 
        # as from user's point of view, he/she doesn't change anything
        # Each key within this JSON object will be tracked individually, 
        # no need for tracking properties as the whole.
        if (@kase.changed_attributes.keys - ["properties"]).present? || linked_cases_changed
          @kase.save!
          @kase.state_machine.edit_case!(acting_user: @user, acting_team: @team)
          @result = :ok
        else
          @result = :no_changes
        end
      end
    rescue Exception => error
      @error_message = error.message
      @result = :error
    end
  end

  private

  def has_linked_cases_changed?
    return has_original_case_changed? || has_related_cases_changed?
  end

  def has_original_case_changed?
    return (@kase.respond_to? :original_case_ids) && 
            @params[:original_case_ids].present? && 
            !two_arrays_is_equal?(@kase.original_case_ids, @params[:original_case_ids])
  end

  def has_related_cases_changed?
    return (@kase.respond_to? :related_case_ids) &&
            @params[:related_case_ids].present? && 
            !two_arrays_is_equal?(@kase.related_case_ids, @params[:related_case_ids])
  end

  def two_arrays_is_equal?(array1, array2)
    return Set.new(array1.map(&:to_s)) == Set.new(array2.map(&:to_s))
  end
end
