module Features
  module Interactions
    def create_and_assign_foi_case(type: Case::FOI::Standard,
                                   user:,
                                   responding_team:,
                                   flag_for_disclosure: false)
      login_step user: user

      kase = create_foi_case_step type: type.to_s.demodulize.downcase,
                                  flag_for_disclosure: flag_for_disclosure
      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def create_and_assign_sar_case(user:, responding_team:, flag_for_disclosure: false)
      login_step user: user

      kase = create_sar_case_step flag_for_disclosure: flag_for_disclosure
      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def create_and_assign_ico_case(user:, responding_team:, original_case_type:)
      login_step user: user

      kase = create_ico_case_step(original_case_type: original_case_type)
      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def assign_unassigned_case(user:, responding_team:)
      login_step user: user
      assign_case_step business_unit: responding_team
      logout_step
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
      sleep 1
      take_on_case_step kase: kase
      if test_undo
        undo_taking_case_on_step kase: kase
        sleep 1
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
                              find_details_page: false,
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

    def close_sar_case(kase:, user:, tmm: false, timeliness:)
      login_step user: user
      go_to_case_details_step kase: kase
      close_sar_case_step timeliness: timeliness, tmm: tmm
    end

    def add_message_to_case(kase:, message:, do_logout: true)
      expect(cases_show_page).to be_displayed(id: kase.id)
      cases_show_page.add_message_to_case(message)
      expect(cases_show_page.messages.first).to have_content(message)
      logout_step if do_logout
    end

    def extend_for_pit(kase:, user:, new_deadline:)
      login_step user: user
      go_to_case_details_step kase: kase
      extend_for_pit_step kase: kase, new_deadline: new_deadline
      logout_step
    end

    def progress_to_disclosure_step(kase:, user:, do_logout: true)
      login_step user: user
      go_to_case_details_step kase: kase
      cases_show_page.actions.progress_to_disclosure.click
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.notice)
        .to have_text 'The Disclosure team has been notified this case is ready for clearance'
      expect(cases_show_page.case_status.details.copy.text).to eq 'Pending clearance'
      logout_step if do_logout
    end


    def search_for(search_phrase:, num_expected_results: nil)
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      cases_search_page.search_query.set search_phrase
      cases_search_page.search_button.click
      unless num_expected_results.nil?
        cases = cases_search_page.case_list
        expect(cases.count).to eq num_expected_results
      end
    end
  end
end
