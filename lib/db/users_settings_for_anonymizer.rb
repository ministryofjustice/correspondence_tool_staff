#
#  A few things for this user settings 
#  - The settings will be stored in S3 bucket on QA env
#  - if you want to store a pre-define one, 
#    the process of storing the hashed password is out of this app for security reason
#    there 2 parts for setting up users 
#     - part 1:  will be performed by anonymizer, handle the existing users and apply suitable way 
#                 to modify the users, then converted into sql 
#     - part 2: will be performed by restoring process, which will create the new users
# @user_settings = [
#   1334 => {
#     "full_name" => "testing-testing-testing"
#   }
# ]
require 'json'

class UsersSettingsForAnonymizer

  USER_SETTINGS_JSON_S3_PATH = "dumps/user_settings.json"

  def initialize(s3_bucket)
    @s3_bucket = s3_bucket
    @user_settings = []
    load_user_settings
  end
  
  def download_user_settings(file_name)
    File.open(file_name, 'wb') do |file|
      @s3_bucket.get_object(USER_SETTINGS_JSON_S3_PATH, target: file)
    end
  end

  def load_from_file(file_name)
    file_content = File.read(file_name)
    @user_settings = JSON.parse(file_content)
  end

  def get_setting(user_id)
    @user_settings[user_id]
  end

  def add_roles
    ActiveRecord::Base.transaction do
      @user_settings.each do | record |
        if record["user_id"].present?
          next
        end
        timestamp = Date.today.strftime("%Y-%m-%d")
        query1 = "insert into users (full_name, email, encrypted_password, created_at, updated_at) 
                  values ('#{record["full_name"]}', '#{record["email"]}', '#{record["encrypted_password"]}', 
                  '#{timestamp}', '#{timestamp}');"
        ActiveRecord::Base.connection.execute(query1)
      end
      @user_settings.each do | record |
        if record["user_id"].present?
          next
        end
        user = User.find_by_email(record["email"])
        if user.present?
          query2 = "insert into teams_users_roles (team_id, user_id, role) values ('#{record["team_id"]}', #{user.id}, '#{record["role"]}');"
          ActiveRecord::Base.connection.execute(query2)
        end
      end
    end        
  end  

  private 

  def load_user_settings
    if @s3_bucket
      response = @s3_bucket.get_object(USER_SETTINGS_JSON_S3_PATH)
      content = response.body.read
      @user_settings = JSON.parse(content)
    end
  end

end
