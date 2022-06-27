class CaseLinkingService

  class CaseLinkingError < RuntimeError; end

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
      begin

        # By using a LinkedCase object here we can retrieve validation errors
        # from the models
        @case_link = LinkedCase.new(
            linked_case_number: @link_case_number.to_s&.strip
        )
        create_links
        @result
      # rescue CaseLinkingError => err
      #   @case.errors.add(:linked_case_number, err.message)
      #   @error = err
      #   @result = :error
      rescue ActiveRecord::RecordInvalid => err
        Rails.logger.error err.to_s
        Rails.logger.error err.backtrace.join("\n\t")
        @error = err
        @result = :error
      end
    end
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
      acting_team = acting_team_for_case_and_user
      @case.state_machine.remove_linked_case!(acting_user: @user,
                                       acting_team: acting_team,
                                       linked_case_id: @link_case.id)
      @link_case.state_machine.remove_linked_case!(acting_user: @user,
                                            acting_team: acting_team,
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

  private

  def create_links
    @case.related_case_links << @case_link

    if @case.valid?
      @linked_case = @case_link.linked_case
      # Log event in both cases
      acting_team = acting_team_for_case_and_user
      @case.state_machine.link_a_case!(acting_user: @user,
                                       acting_team: acting_team,
                                       linked_case_id: @linked_case.id)
      @linked_case.state_machine.link_a_case!(acting_user: @user,
                                              acting_team: acting_team,
                                              linked_case_id: @case.id)
      @result = :ok
    else
      add_case_link_errors_to_case(@case_link, @case)
      @result = :validation_error
    end
  end

  def acting_team_for_case_and_user
    if @case.sar? || @case.overturned_ico_sar?
      team = @user.teams_for_case(@case).detect{ |t| t.role == 'manager'}
      raise CaseLinkingError.new('User requires manager role for linking SAR cases') if team.nil?
      team
    else
      @user.teams_for_case(@case).first
    end
  end

end
