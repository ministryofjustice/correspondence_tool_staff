require 'rails_helper'

feature 'viewing details of case in the system' do

  # TODO: Add test that DACU shows up when the case is marked as responded
  given(:responder) { create :responder }
  given(:responding_team) { responder.responding_teams.first }

  given(:internal_gq_deadline) do
    DeadlineCalculator.internal_deadline(gq).strftime(Settings.default_date_format)
  end
  given(:external_gq_deadline) do
    DeadlineCalculator.external_deadline(gq).strftime(Settings.default_date_format)
  end

  background do
    login_as responder
  end

  # scenario 'when the case is a general enquiry' do
  #   cases_show_page.load id: gq.id

  #   expect(cases_show_page).to have_case_heading
  #   expect(cases_show_page.case_heading.case_number).to have_content(gq.number)
  #   expect(cases_show_page.case_heading).to have_content(gq.subject)

  #   expect(cases_show_page).to have_no_escalation_notice

  #   expect(cases_show_page).to have_sidebar
  #   expect(cases_show_page.sidebar).to have_external_deadline
  #   expect(cases_show_page.sidebar.external_deadline).
  #     to have_content(external_gq_deadline)
  #   expect(cases_show_page.sidebar.status).to have_content('Response')
  #   expect(cases_show_page.sidebar.who_its_with)
  #     .to have_content(gq.responding_team.name)

  #   expect(cases_show_page.sidebar.name).to have_content('Gina GQ')
  #   expect(cases_show_page.sidebar.requester_type).
  #     to have_content(gq.requester_type.humanize)
  #   expect(cases_show_page.sidebar.email).
  #     to have_content('gina.gq@testing.digital.justice.gov.uk')
  #   expect(cases_show_page.sidebar.postal_address).to have_content(gq.postal_address)

  #   expect(cases_show_page.message).to have_content('viewing gq details test message')
  #   expect(cases_show_page.received_date).to have_content(foi_received_date)
  # end

  given(:foi) do
    create :accepted_case,
           requester_type: :offender,
           name: 'Freddie FOI',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'this is a foi',
           message: 'viewing foi details test message',
           responding_team: responding_team
  end

  given(:old_foi) do
    create :accepted_case,
           received_date: 31.days.ago,
           responding_team: responding_team
  end

  given(:foi_received_date) do
    foi.received_date.strftime(Settings.default_date_format)
  end
  given(:foi_escalation_deadline) do
    DeadlineCalculator.escalation_deadline(foi).strftime(Settings.default_date_format)
  end
  given(:external_foi_deadline) do
    DeadlineCalculator.external_deadline(foi).strftime(Settings.default_date_format)
  end


  context 'when the case is an assigned non-trigger foi request' do
    scenario 'displays all case content' do
      cases_show_page.load id: foi.id

      expect(cases_show_page).to have_page_heading
      expect(cases_show_page.page_heading.sub_heading).to have_content(foi.number)
      expect(cases_show_page.page_heading.heading.text).to have_content(foi.subject)

      expect(cases_show_page.request.message).to have_content('viewing foi details test message')

      expect(cases_show_page).to have_case_history
      expect(cases_show_page.case_history.entries.size).to eq 2
      expect(cases_show_page.case_history.entries.first).to have_content "Accepted by Business unit"
      expect(cases_show_page.case_history.entries.last).to have_content "Assign responder"
    end

    scenario 'User views the case while its within "Day 3"' do
      Timecop.freeze foi.received_date do
        cases_show_page.load id: foi.id
        expect(cases_show_page).to have_escalation_notice
        expect(cases_show_page.escalation_notice).to have_text(foi_escalation_deadline)
      end
    end

    scenario 'User views the case that is outside "Day 6"' do
      cases_show_page.load id: old_foi.id
      expect(cases_show_page).to have_no_escalation_notice
    end

  end


  context 'viewing case request with a long message' do

    given(:long_message) {
      "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney "+
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " +
          "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " +
          "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."
    }

    given(:short_message) {
      "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
          "and going through th"
    }


    given(:accepted_case) {
      create :accepted_case, message:long_message,responding_team: responding_team
    }

    scenario 'Clicking "Show more/Less more" link under a long request', js:true do
      cases_show_page.load id: accepted_case.id

      request = cases_show_page.request

      request.show_more_link.click
      expect(request.show_more_link.text).to eq 'Show less'
      expect(request).to have_collapsed_text
      expect(request).to have_no_ellipsis

      request.show_more_link.click
      expect(request.show_more_link.text).to eq 'Show more'
      expect(request).to have_ellipsis
      expect(request).to have_no_collapsed_text
    end
  end

  context 'responder is member of multiple responding teams' do
    let(:other_responding_team) { create(:responding_team) }

    before do
      responder.responding_teams << other_responding_team
      expect(responder.responding_teams.count).to eq 2
      @kase = create :accepted_case, responding_team: other_responding_team
    end

    scenario 'viewing details of simple case' do
      cases_show_page.load id: @kase.id
      expect(cases_show_page).to be_displayed(@kase.id)
    end

    scenario 'viewing open cases list' do
      case1 = create :awaiting_responder_case,
                     responding_team: responding_team
      case2 = create :awaiting_responder_case,
                     responding_team: other_responding_team

      open_cases_page.load
      expect(case1.number).to be_in(open_cases_page.case_numbers)
      expect(case2.number).to be_in(open_cases_page.case_numbers)
    end

  end
end
