class CasePrinter

  def initialize(case_or_case_id)
    @case = case_or_case_id.is_a?(Case::Base) ? case_or_case_id : Case::Base.find(case_or_case_id)
    @lines = []
  end

  def print
    generate_lines
    @lines.each { |l| puts l }
    nil
  end

  def generate_lines
    @lines <<  "Case id: #{@case.id}   from #{@case.name}    title: #{@case.message}"
    @lines <<  "               current_sate #{@case.current_state}"
    @lines <<  "                   workflow #{@case.workflow}"
    @lines <<   "Assignments:"
    @case.assignments.each do |a|
      @lines <<   sprintf("    id: %-5d  role: %-12s state: %-12s team: %-5d %20s  user: %-5s %s", a.id, a.role, a.state, a.team.id, a.team.name, a.user_id.to_s, a.user&.full_name )
    end
    @lines << "Transitions:"
    @case.transitions.order(:id).each do |t|
      @lines <<   sprintf("    id: %-5d   event: %s", t.id, t.event)
      @lines <<   sprintf("             to_state: %s", t.to_state)
      @lines <<   sprintf("        acting team: %-5s %-20s acting user: %-5s %s", t.acting_team_id, t.acting_team&.name, t.acting_user_id, t.acting_user&.full_name)
      @lines <<   sprintf("        target team: %-5s %-20s target user: %-5s %s", t.target_team_id, t.target_team&.name, t.target_user_id, t.target_user&.full_name)
    end

  end
end
