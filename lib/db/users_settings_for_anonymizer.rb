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
require "json"

class UsersSettingsForAnonymizer
  USER_SETTINGS_JSON_S3_PATH = "dumps/user_settings.json".freeze

  def initialize
    @user_settings = []
  end

  def download_user_settings_from_s3(s3_bucket, file_name)
    if s3_bucket
      File.open(file_name, "wb") do |file|
        s3_bucket.get_object(USER_SETTINGS_JSON_S3_PATH, target: file)
      end
    end
  end

  def get_setting(user_id)
    @user_settings[user_id]
  end

  def add_roles
    new_user_list = @user_settings["new"]
    if new_user_list.present?
      generate_new_users(new_user_list)
      update_team_and_role(new_user_list)
    end
  end

  def load_user_settings_from_s3(s3_bucket)
    if s3_bucket
      begin
        response = s3_bucket.get_object(USER_SETTINGS_JSON_S3_PATH)
        content = response.body.read
        @user_settings = JSON.parse(content)
      rescue Aws::S3::Errors::NoSuchKey
        # Carry on if settings don't exist in bucket
      end
    end
  end

  def load_user_settings_from_local(full_setting_file)
    file_content = File.read(full_setting_file)
    @user_settings = JSON.parse(file_content)
  end

  def upload_settings_to_s3(s3_bucket, setting_file)
    if s3_bucket
      response = s3_bucket.put_object(
        USER_SETTINGS_JSON_S3_PATH,
        File.read(setting_file),
        metadata: { "created_at" => Time.zone.today.to_s },
      )
      if response && response["etag"].present?
        puts "done".green
      else
        puts "Failed to upload this file, the response is #{response}"
        raise "Failed to upload #{upload_file}, will try again!"
      end
    end
  end

private

  def generate_new_users(new_user_list)
    # The user is only for getting the encrypted password
    user = User.new(full_name: "anonymizeruser")
    new_user_list.each do |record|
      next unless new_user?(record["email"])

      timestamp = Time.zone.today.strftime("%Y-%m-%d")
      user.password = record["password"]
      query1 = "insert into users (full_name, email, encrypted_password, created_at, updated_at)
                values ('#{record['full_name']}', '#{record['email']}', '#{user.encrypted_password}',
                '#{timestamp}', '#{timestamp}');"
      begin
        ActiveRecord::Base.connection.execute(query1)
      rescue StandardError => e
        puts e.message
      end
    end
  end

  def new_user?(email)
    user = User.where(email: email.downcase).singular_or_nil
    user.nil?
  end

  def update_team_and_role(new_user_list)
    new_user_list.each do |record|
      user = User.find_by_email(record["email"])
      team = Team.find_by_name(record["team_name"])
      next unless user.present? && team.present?

      query2 = "insert into teams_users_roles (team_id, user_id, role) values ('#{team.id}', #{user.id}, '#{record['role']}');"
      begin
        ActiveRecord::Base.connection.execute(query2)
      rescue StandardError => e
        puts e.message
      end
    end
  end
end
