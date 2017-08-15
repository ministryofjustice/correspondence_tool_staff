class CasePrinter

  def initialize(case_id)
    @case = Case.find case_id
  end

  def print
    puts "Case id: #{@case.id}   from #{@case.name}    title: #{@case.message}"
    puts "Assignments:"
    @case.assignments.each do |a|
      puts sprintf("    id: %-5d  role: %-12s state: %-12s team: %-5d %s", a.id, a.role, a.state, a.team.id, a.team.name)
      # puts "    id: #{a.id}  state #{a.state}  team: #{a.team.id}: #{a.team.name}  user: #{a.user_id}: #{a.user&.full_name} role: #{a.role}"
    end
    puts "Transitions:"
    @case.transitions.each do |t|
      puts sprintf("    id: %-5d   event: %s", t.id, t.event)
      puts sprintf("        acting team: %-5s %-20s acting user: %-5s %s", t.acting_team_id, t.acting_team&.name, t.acting_user_id, t.acting_user&.full_name)
      puts sprintf("        target team: %-5s %-20s target user: %-5s %s", t.target_team_id, t.target_team&.name, t.target_user_id, t.target_user&.full_name)
    end

  end
end
