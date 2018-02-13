class CaseLinkingService
  attr_reader :result, :error

  def initialize(user, kase, link_case_number)
    @user = user
    @case = kase
    @link_case_number = link_case_number
    @link_case = nil
    @result = :incomplete
  end

  def create
    if validate_params
      ActiveRecord::Base.transaction do

        #Create the links
        @case.add_linked_case(@link_case)

        # Log event in both cases
        @case.state_machine.link_a_case!(acting_user: @user,
                                         acting_team: @user.teams_for_case(@case).first,
                                         linked_case_id: @link_case.id)
        @link_case.state_machine.link_a_case!(acting_user: @user,
                                              acting_team: @user.teams_for_case(@case).first,
                                              linked_case_id: @case.id)
        @result = :ok
      end
    end
    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
  end

  private

  def validate_params
    validate_case_number_present
    validate_linked_case_not_this_case
    validate_linked_case_exists
    validate_sar_case_linking
  end

  def validate_sar_case_linking
    if @case.is_a?(Case::SAR)
      unless @link_case.is_a?(Case::SAR)
        @case.errors.add(:linked_case_number, "can't link a SAR case to a non-SAR case")
        @result = :validation_error
      end
    else
      if @link_case.is_a?(Case::SAR)
        @case.errors.add(:linked_case_number, "can't link a non-SAR case to a SAR case")
        @result = :validation_error
      end
    end
    @result = :ok if @case.errors.empty?
  end

  def validate_case_number_present
    unless @link_case_number.present?
      @case.errors.add(:linked_case_number, "can't be blank")
      @result = :validation_error
    end
  end

  def validate_linked_case_not_this_case
    if @link_case_number == @case.number
      @case.errors.add(:linked_case_number, "can't link to the same case")
      @result = :validation_error
    end
  end

  def validate_linked_case_exists
    if @case.errors.empty?
      if Case::Base.where(number: @link_case_number).exists?
        @link_case = Case::Base.where(number: @link_case_number).first
        true
      else
        @case.errors.add(
          :linked_case_number,
          "does not exist"
        )
        @result = :validation_error
        false
      end
    end
  end

end
