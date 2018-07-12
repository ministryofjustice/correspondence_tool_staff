require 'rails_helper'


feature 'cases requiring clearance by disclosure specialist' do
  include CaseDateManipulation
  include Features::Interactions

  given(:disclosure_specialist)       { create :disclosure_specialist }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }

  scenario 'taking_on, undoing and de-escalating a case as a disclosure specialist', js: true do
    kase = create :accepted_ico_foi_case, :flagged,
                  approving_team: team_dacu_disclosure

    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1

    take_on_case_step(kase: kase)
    undo_taking_case_on_step(kase: kase)
  end
end
