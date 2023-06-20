require "rails_helper"

feature "viewing details of case in the system" do
  # TODO: Add test that DACU shows up when the case is marked as responded
  given(:responder)       { responding_team.responders.first }
  given(:responding_team) { find_or_create :foi_responding_team }

  given(:foi) do
    create :accepted_case,
           requester_type: :journalist,
           name: "Freddie FOI",
           email: "freddie.foi@testing.digital.justice.gov.uk",
           subject: "this is a foi",
           responding_team:,
           responder:,
           message: "viewing foi details test message"
  end

  given(:old_foi) do
    create :accepted_case,
           received_date: 31.days.ago,
           responding_team:
  end

  given(:foi_received_date) do
    foi.received_date.strftime(Settings.default_date_format)
  end
  given(:foi_escalation_deadline) do
    foi.deadline_calculator
      .escalation_deadline
      .strftime(Settings.default_date_format)
  end
  given(:external_foi_deadline) do
    foi.deadline_calculator
      .external_deadline
      .strftime(Settings.default_date_format)
  end

  background do
    login_as responder
  end

  context "when the case is an assigned non-trigger foi request" do
    scenario "displays all case content" do
      cases_show_page.load id: foi.id
      expect(cases_show_page).to have_page_heading
      expect(cases_show_page.page_heading.sub_heading).to have_content(foi.number)
      expect(cases_show_page.page_heading.heading.text).to have_content(foi.subject)

      expect(cases_show_page.request.message).to have_content("viewing foi details test message")

      expect(cases_show_page).to have_case_history
      expect(cases_show_page.case_history.entries.size).to eq 3
      expect(cases_show_page.case_history.entries.first).to have_content "Accepted by Business unit"
      expect(cases_show_page.case_history.entries[1]).to have_content "Assign responder"
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

  context "with FOI case with both full case details and attachment" do
    given(:request_file) { "#{Faker::Internet.slug}.pdf" }
    given(:foi) do
      create :accepted_case, :case_sent_by_post,
             requester_type: :journalist,
             name: "Freddie FOI",
             email: "freddie.foi@testing.digital.justice.gov.uk",
             subject: "this is a foi",
             message: "viewing foi details test message",
             responding_team:,
             uploaded_request_files: [request_file]
    end

    scenario "displaying case details" do
      cases_show_page.load id: foi.id

      expect(cases_show_page.request).to have_message
      expect(cases_show_page.request.message.text)
        .to eq "viewing foi details test message"
      expect(cases_show_page.request).to have_attachments
      expect(cases_show_page.request.attachments.count).to eq 1
      expect(cases_show_page.request.attachments[0].collection[0].filename.text)
        .to eq request_file
    end
  end

  context "when viewing case request with a long message" do
    given(:long_message) do
      "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " \
        "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " \
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " \
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
        "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " \
        "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " \
        "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."
    end

    given(:short_message) do
      "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " \
        "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " \
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " \
        "and going through th"
    end

    given(:accepted_case) do
      create :accepted_case, message: long_message, responding_team:
    end

    scenario 'Clicking "Show more/Less more" link under a long request', js: true do
      cases_show_page.load id: accepted_case.id

      request = cases_show_page.request

      request.show_more_link.click
      expect(request.show_more_link.text).to eq "Show less"
      expect(request).to have_collapsed_text
      # expect(request).to have_hidden_ellipsis
      expect(request).to have_no_ellipsis

      request.show_more_link.click
      expect(request.show_more_link.text).to eq "Show more"
      expect(request).to have_ellipsis
      # expect(request).to have_hidden_collapsed_text
      expect(request).to have_no_collapsed_text
    end
  end

  context "when responder is member of multiple responding teams" do
    let(:other_responding_team) { create(:responding_team) }

    before do
      responder.responding_teams << other_responding_team
      expect(responder.responding_teams.count).to eq 2
      @kase = create :accepted_case, responding_team: other_responding_team
    end

    scenario "viewing details of simple case" do
      cases_show_page.load id: @kase.id
      expect(cases_show_page).to be_displayed(@kase.id)
    end

    scenario "viewing open cases list" do
      case1 = create(:awaiting_responder_case,
                     responding_team:)
      case2 = create :awaiting_responder_case,
                     responding_team: other_responding_team

      open_cases_page.load
      expect(case1.number).to be_in(open_cases_page.case_numbers)
      expect(case2.number).to be_in(open_cases_page.case_numbers)
    end
  end
end
