require 'rails_helper'

feature 'viewing response details' do
  given(:assigner) { create :assigner }
  given(:drafter)  { create :drafter }

  context 'as an assigner' do
    before do
      login_as assigner
    end

    context 'with a case being drafter' do
      given(:drafting_case)  { create :case_with_response }

      scenario 'when the case has a response' do
        cases_show_page.load(id: drafting_case.id)

        expect(cases_show_page).not_to have_response_details
      end
    end

    context 'with a case marked as responded' do
      given(:responded_case) do
        create :responded_case,
               assigner: assigner,
               drafter: drafter
      end
      given(:response) { responded_case.attachments.first }

      scenario 'when the case has a response' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page).to have_response_details
        expect(cases_show_page.response_details.responses.first)
          .to have_content(response.filename)
        expect(cases_show_page.response_details.responder)
          .to have_content(drafter.full_name)
      end

      given(:case_with_many_responses) do
        create :responded_case,
               responses: build_list(:correspondence_response, 4),
               assigner: assigner,
               drafter: drafter
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
      given(:closed_case)  { create :closed_case, drafter: drafter }

      scenario 'when the case has a response' do
        cases_show_page.load(id: closed_case.id)

        expect(cases_show_page).to have_response_details
        expect(cases_show_page.response_details.responder)
          .to have_content(drafter.full_name)
        expect(cases_show_page.response_details.date_responded)
          .to have_content(closed_case.date_responded.strftime('%e %b %Y'))
      end
    end

  end

  context 'as a drafter' do
    before do
      login_as drafter
    end

    context 'with a case being drafted' do
      given(:accepted_case) { create :accepted_case, drafter: drafter }
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
      end
    end
  end
end
