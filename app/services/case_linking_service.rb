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
    ActiveRecord::Base.transaction do

      # By using a LinkedCase object here we can retrieve validation errors
      # from the models
      @case_link = LinkedCase.new(
        linked_case_number: @link_case_number.to_s&.strip
      )

      #Create the links
      @case.related_case_links << @case_link

      if @case.valid?
        @linked_case = @case_link.linked_case
        # Log event in both cases
        @case.state_machine.link_a_case!(acting_user: @user,
                                         acting_team: @user.teams_for_case(@case).first,
                                         linked_case_id: @linked_case.id)
        @linked_case.state_machine.link_a_case!(acting_user: @user,
                                                acting_team: @user.teams_for_case(@case).first,
                                                linked_case_id: @case.id)
        @result = :ok
      else
        add_case_link_errors_to_case(@case_link, @case)
        @result = :validation_error
      end
    end
    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
  end

  def add_case_link_errors_to_case(case_link, kase)
    if case_link.errors[:linked_case_number].present?
      kase.errors.add(:linked_case_number,
                      case_link.errors[:linked_case_number].first)
    elsif case_link.errors[:linked_case].present?
      kase.errors.add(:linked_case_number,
                       case_link.errors[:linked_case].first)
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      # find the linked case
      @link_case = @case.related_cases.find_by(number: @link_case_number)

      # Destroy the links
      @case.related_cases.destroy(@link_case)

      # Log event in both cases
      @case.state_machine.remove_linked_case!(acting_user: @user,
                                       acting_team: @user.teams_for_case(@case).first,
                                       linked_case_id: @link_case.id)
      @link_case.state_machine.remove_linked_case!(acting_user: @user,
                                            acting_team: @user.teams_for_case(@case).first,
                                            linked_case_id: @case.id)

      @result = :ok

    end

    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
  end
end
