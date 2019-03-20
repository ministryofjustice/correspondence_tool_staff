require 'securerandom'

# A DefaultUser was introduced in March 2019 due to the
# requirement that all new Cases should have the creator
# user id saved.
#
# Existing Cases were retrospectively
# assigned to 'DefaultUser' so that creator
# validation for Cases does not fail.
class DefaultUser < User
  ID = -100
  EMAIL = Settings.default_user_email

  # Ignore any attempts to change the DefaultUser Id
  def id=(_id)
    write_attribute :id, ID
  end

  # Ignore any attempts to change the DefaultUser Email
  def email=(_email)
    write_attribute :email, EMAIL
  end

  def self.build!
    default_user = User.find_by(id: ID)

    if !default_user
      DefaultUser.create!(
        id: ID,
        email: EMAIL,
        password: SecureRandom.base64(20),
        full_name: ''
      )
    end
  end

  protected

  def skip_full_name_check?
    true
  end
end
