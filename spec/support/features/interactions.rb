module Features
  module Interactions
    def create_and_assign_case(type:,
                               user:,
                               responding_team:,
                               flag_for_disclosure: false)
      login_step user: user

      kase = create_case_step type: type.to_s.downcase.gsub(/\W/, ''),
                              flag_for_disclosure: flag_for_disclosure
      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def take_case_on(kase:,
                     user:,
                     do_login: true,
                     do_logout: true,
                     test_undo: false)
      if do_login
        login_step user: user
        go_to_incoming_cases_step
      else
        expect(incoming_cases_page).to be_shown
        expect(incoming_cases_page.user_card.greetings)
          .to have_content user.full_name
      end
      take_on_case_step kase: kase
      if test_undo
        undo_taking_case_on_step kase: kase
        take_on_case_step kase: kase
      end
      go_to_incoming_cases_step expect_not_to_see_cases: [kase]
      logout_step if do_logout
    end

    def accept_case(kase:, user:, do_logout: true)
      login_step user: user
      go_to_case_details_step kase: kase
      accept_responder_assignment_step
      logout_step if do_logout
    end

    def edit_case(kase:, user:, subject: nil)
      login_step user: user
      go_to_case_details_step kase: kase
      edit_case_step kase: kase, subject: subject
      logout_step
    end

    def upload_response(kase:,
                        user:,
                        file:,
                        do_login: true,
                        do_logout: true)
      if do_login
        login_step user: user
      else
        expect(cases_show_page).to be_displayed
        expect(cases_show_page.user_card.greetings)
          .to have_content user.full_name
      end
      cases_show_page.load(id: kase.id)
      upload_response_step file: file
      go_to_case_details_step kase: kase.reload,
                              expected_response_files: [File.basename(file)]
      logout_step if do_logout
    end

    def clear_response(kase:, user:, expected_team:, expected_status:)
      login_step user: user
      go_to_case_details_step kase: kase
      approve_case_step kase: kase,
                        expected_team: expected_team,
                        expected_status: expected_status
      logout_step
    end

    def mark_case_as_sent(kase:, user:, do_login: true)
      if do_login
        login_step user: user
        go_to_case_details_step kase: kase
      else
        expect(cases_show_page).to be_displayed
        expect(cases_show_page.user_card.greetings)
          .to have_content user.full_name
      end
      mark_case_as_sent_step
      logout_step
    end

    def close_case(kase:, user:)
      login_step user: user
      go_to_case_details_step kase: kase
      close_case_step
    end
  end
end
