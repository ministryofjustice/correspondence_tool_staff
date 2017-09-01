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
        @user.errors[:base] << 'This user is already in the team'
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
      @team.__send__(@role.pluralize) << @user
      @team.save!
      @result = :existing_ok
    else
      error_message = "An existing user with this email address already exists with the name: #{@user.full_name}"
      @user = User.new(@params)
      @user.errors[:base] << error_message
    end

  end

  def create_new_user
    @user = User.new(@params)
    @user.password = SecureRandom.random_number(36**13).to_s(36)
    @user.password_confirmation = @user.password
    if @user.valid? && @team.present?
      @team.__send__(@role.pluralize) << @user
      @result = :ok
    end
  end

  def full_names_match
    @user.full_name.downcase == @params[:full_name].downcase
  end


end
