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
end

