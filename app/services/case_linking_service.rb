class CaseLinkingService
  attr_reader :result, :error

  def initialize(user, kase, link_case_number)
    @user = user
    @case = kase
    @link_case_number = link_case_number
    @link_case = nil
    @result = :incomplete
  end

  def call
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
    unless @link_case_number.present?
      @case.errors.add(:linked_case_number, "can't be blank")
      @result = :validation_error
    end

    if @link_case_number == @case.number
      @case.errors.add(:linked_case_number, "can't link to the same case")
      @result = :validation_error
    end

    unless link_case_exists?
      @result = :validation_error
    end

    @result = :ok if @case.errors.empty?
  end

  def link_case_exists?
    if @case.errors.empty?
      if Case.where(number: @link_case_number).exists?
        @link_case = Case.where(number: @link_case_number).first
        true
      else
        @case.errors.add(
          :linked_case_number,
          "does not exist"
        )
        false
      end
    end
  end

end
