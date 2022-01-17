#
#  A few things for this user settings 
#  - The table for storing user settings won't be part of main app. so going to use activemodelto do it
#  - if you want to store a pre-define one, 
#    the process of storing the hashed password is out of this app for security reason
#    there 2 parts for setting up users 
#     - part 1:  will be performed by anonymizer, handle the existing users and apply suitable way 
#                 to modify the users, then converted into sql 
#     - part 2: will be performed by restoring process, which will create the new users
class UsersSettingsForAnonymizer

  class << self
    
    def get_setting(user_id)
      query = <<-SQL
            SELECT * FROM users_settings_for_anonymizer where user_id = #{user_id}
            SQL
      users = ActiveRecord::Base.connection.execute(query)
      if users.present?
        users[0]
      else
        nil
      end
    end

    def add_roles
      # Create the roles defined in the users_settings_for_anonymizer
      query = <<-SQL
            SELECT * FROM users_settings_for_anonymizer where user_id is null
            SQL
      users = ActiveRecord::Base.connection.execute(query)
      ActiveRecord::Base.transaction do
        users.each do | record |
          timestamp = Date.today.strftime("%Y-%m-%d")
          query1 = "insert into users (full_name, email, encrypted_password, created_at, updated_at) 
                    values ('#{record["full_name"]}', '#{record["email"]}', '#{record["encrypted_password"]}', 
                    '#{timestamp}', '#{timestamp}');"
          ActiveRecord::Base.connection.execute(query1)
        end
        users.each do | record |
          user = User.find_by_email(record["email"])
          if user.present?
            query2 = "insert into teams_users_roles (team_id, user_id, role) values ('#{record["team_id"]}', #{user.id}, '#{record["role"]}');"
            ActiveRecord::Base.connection.execute(query2)
          end
        end
      end        
    end  

  end 

end