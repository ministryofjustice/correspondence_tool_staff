class UserCreationService
  attr_reader :result, :user

  def initialize(team:, params:)
    @team = team
    @role = @team.role
    @params = params
    @result = :error
  end

  def call
    @user = User.where(email: @params[:email].downcase).singular_or_nil
    if @user
      if @user.team_roles.map(&:team_id).include?(@team.id)
        @user.errors.add(:base, "This user is already in the team")
      else
        update_existing_user
      end
    else
      create_new_user
    end
  end

private

  def update_existing_user
    if full_names_match
      # Add user to the teams
      add_user_to_teams
      @team.save!

      # Remove soft delete if their account was previously deleted
      @user.update!(deleted_at: nil) if @user.deleted_at?

      @result = :existing_ok
    else
      error_message = "The user with that email address has a different name. To add them to the team, enter their full name as #{@user.full_name.strip}"
      @user = User.new(@params)
      @user.errors.add(:base, error_message)
    end
  end

  def create_new_user
    @user = User.new(@params)
    @user.password = SecureRandom.random_number(36**13).to_s(36)
    @user.password_confirmation = @user.password
    if @user.valid? && @team.present?
      add_user_to_teams
      @result = :ok
    end
  end

  def full_names_match
    @user.full_name.strip.downcase == @params[:full_name].strip.downcase
  end

  def add_user_to_teams
    @team.__send__(@role.pluralize) << @user
    @team.previous_teams.each do |team|
      team.__send__(@role.pluralize) << @user
    end
  end
end
