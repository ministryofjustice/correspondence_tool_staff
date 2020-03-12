namespace :db do
  desc 'Fix approver assignments'
  task :fix_approver_assignments => :environment do
    approver_teams = ["DISCLOSURE", "DISCLOSURE-BMT", "PRESS-OFFICE", "PRIVATE-OFFICE"]
    approver_teams.each do |approver_team|
      ActiveRecord::Base.transaction do
        begin
          new_team = Team.find_by_code(approver_team)
          num = new_team.old_team&.assignments&.approving&.count || 0
          puts "Moving #{num} assignments for #{new_team.code}"
          if num > 0
            puts "Changing team ID from #{new_team.old_team.id} to #{new_team.id} for assignment ids:"
            new_team.old_team&.assignments&.approving.each {|a| puts "   #{a.id}" }
          end
          new_team.old_team&.assignments&.approving&.update_all(team_id: new_team.id)
          puts "...done"
        rescue  => err
          puts "!!! error received: #{err.class} #{err.message}"
          puts err.backtrace.join("\n\t")
        end
      end
    end
  end
  desc 'Add users to previous team incarnations'
  task :add_users_to_previous_teams => :environment do
    users = User.all
    puts "Updating team roles for #{users.length} users... "
    users.each do |user|
      puts "* Checking team roles for #{user.full_name}"
      user.teams.each do |team|
        user_teams = user.teams.pluck :id
        team.previous_teams.each do |team_id|
          team = Team.find_by_id(team_id)
          unless user.teams.reload.include? team
            puts " - adding #{team.role} role for #{team.name}"
            team.__send__(team.role.pluralize) << user
          end
        end
      end
    end
    puts "...completed"
  end
end

