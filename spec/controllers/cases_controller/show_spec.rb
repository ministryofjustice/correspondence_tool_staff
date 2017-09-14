require "rails_helper"

describe CasesController, type: :controller do
  let(:responder)          { create :responder }
  let(:another_responder)  { create :responder }
  let(:responding_team)    { responder.responding_teams.first }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:assigned_case)      { create :assigned_case,
                                    responding_team: responding_team }
  let(:accepted_case)      { create :accepted_case, responder: responder }
  let(:unassigned_case)    { create(:case) }
  let(:case_with_response) { create :case_with_response, responder: responder }
  let(:flagged_accepted_case) { create :accepted_case, :flagged_accepted,
                                       responding_team: responding_team,
                                       approver: disclosure_specialist,
                                       responder: responder}

  
end
