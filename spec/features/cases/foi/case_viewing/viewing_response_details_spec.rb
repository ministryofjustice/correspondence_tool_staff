require 'rails_helper'

feature 'viewing response details' do
  given(:manager)         { create :manager }
  given(:responder)       { create :responder }
  given(:responding_team) { responder.responding_teams.first }

  context 'as an manager' do
    before do
      login_as manager
    end

    context 'with a case being responder' do
      given(:drafting_case)  { create :case_with_response }

      scenario 'when the case has a response' do
        cases_show_page.load(id: drafting_case.id)

        expect(cases_show_page).not_to have_response_details
      end
    end

    context 'with a case marked as responded' do
      given(:responded_case) do
        create :responded_case,
               manager: manager,
               responder: responder
      end
      given(:response) { responded_case.attachments.first }

      scenario 'when the case has a response' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page).to have_response_details
        expect(cases_show_page.response_details.responses.first)
          .to have_content(response.filename)
        expect(cases_show_page.response_details.responder)
          .to have_content(responding_team.name)
      end

      given(:case_with_many_responses) do
        create :responded_case,
               responses: build_list(:correspondence_response, 4),
               manager: manager,
               responder: responder
      end
      given(:responses) { case_with_many_responses.attachments }

      scenario 'with a case with multiple uploaded responses' do
        responded_case.attachments << build(:case_attachment)
        cases_show_page.load(id: responded_case.id)

        rendered_filenames = cases_show_page.response_details.responses
                               .map do |response|
          response.filename.text
        end

        sorted_response_filenames =
          responded_case.attachments.response.map(&:filename).sort
        expect(rendered_filenames).to eq sorted_response_filenames
      end
    end

    context 'with a closed case' do
      given(:closed_case)  { create :closed_case, responder: responder }

      scenario 'when the case has a response' do
        cases_show_page.load(id: closed_case.id)

        expect(cases_show_page).to have_response_details
        expect(cases_show_page.response_details.responder)
          .to have_content(responding_team.name)
        expect(cases_show_page.response_details.date_responded)
          .to have_content(closed_case.date_responded.strftime('%e %b %Y'))
        expect(cases_show_page.response_details.outcome)
            .to have_content(closed_case.outcome.name)
      end
    end

  end

  context 'as a responder' do
    before do
      login_as responder
    end

    context 'with a case being drafted' do
      given(:accepted_case) { create :accepted_case, responder: responder }
      given(:response)      { build  :case_response }

      scenario 'when the case has no responses' do
        cases_show_page.load(id: accepted_case.id)
        expect(cases_show_page).not_to have_response_details
      end

      scenario 'when the case has a response' do
        accepted_case.attachments << response
        cases_show_page.load(id: accepted_case.id)
        expect(cases_show_page).to have_response_details
        expect(cases_show_page.response_details).not_to have_responder
        expect(cases_show_page.response_details).not_to have_date_responded
        expect(cases_show_page.response_details).not_to have_outcome
      end
    end
  end
end
