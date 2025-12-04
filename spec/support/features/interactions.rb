module Features
  module Interactions
    include Interactions::OverturnedICO

    def create_and_assign_foi_case(user:, responding_team:, type: Case::FOI::Standard,
                                   flag_for_disclosure: false)
      login_step(user:)

      kase = if type == Case::FOI::Standard
               create_foi_case_step(type: type.to_s.demodulize.downcase,
                                    flag_for_disclosure:)
             else
               create_foi_case_auto_flagged_step type: type.to_s.demodulize.downcase
             end

      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def create_and_assign_sar_case(user:, responding_team:, flag_for_disclosure: false)
      login_step(user:)

      kase = create_sar_case_step(flag_for_disclosure:)
      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def create_and_assign_ico_case(user:,
                                   responding_team:,
                                   original_case:,
                                   related_cases: [])
      login_step(user:)

      kase = create_ico_case_step(original_case:,
                                  related_cases:)
      assign_case_step business_unit: responding_team
      logout_step
      kase
    end

    def assign_unassigned_case(user:, responding_team:)
      login_step(user:)
      assign_case_step business_unit: responding_team
      logout_step
    end

    def take_case_on(kase:,
                     user:,
                     do_login: true,
                     do_logout: true,
                     test_undo: false)
      if do_login
        login_step(user:)
        go_to_incoming_cases_step
      else
        expect(incoming_cases_page).to be_shown
        expect(incoming_cases_page.user_card.greetings)
          .to have_content user.full_name
      end
      sleep 1
      take_on_case_step(kase:)
      if test_undo
        undo_taking_case_on_step(kase:)
        sleep 1
        take_on_case_step kase:
      end
      go_to_incoming_cases_step expect_not_to_see_cases: [kase]
      logout_step if do_logout
    end

    def accept_case(kase:, user:, do_logout: true)
      login_step(user:)
      go_to_case_details_step(kase:)
      accept_responder_assignment_step
      logout_step if do_logout
    end

    def edit_case(kase:, user:, subject: nil)
      login_step(user:)
      go_to_case_details_step(kase:)
      edit_case_step(kase:, subject:)
      logout_step
    end

    def upload_response(kase:,
                        user:,
                        file:,
                        do_login: true,
                        do_logout: true)
      if do_login
        login_step(user:)
      else
        expect(cases_show_page).to be_displayed
        expect(cases_show_page.user_card.greetings)
          .to have_content user.full_name
      end
      cases_show_page.load(id: kase.id)
      upload_response_step(file:)
      go_to_case_details_step kase: kase.reload,
                              find_details_page: false,
                              expected_response_files: [File.basename(file)]
      logout_step if do_logout
    end

    def clear_response(kase:,
                       user:,
                       expected_team:,
                       expected_status:,
                       expected_notice: "#{expected_team.name} has been notified that the response is ready to send.")
      login_step(user:)
      go_to_case_details_step(kase:)
      approve_case_step(kase:,
                        expected_team:,
                        expected_status:,
                        expected_notice:)
      logout_step
    end

    def mark_case_as_sent(kase:, user:,
                          expected_status: "Ready to close",
                          do_login: true,
                          expected_to_be_with: "Disclosure BMT")
      if do_login
        login_step(user:)
        go_to_case_details_step kase:
      else
        expect(cases_show_page).to be_displayed
        expect(cases_show_page.user_card.greetings)
          .to have_content user.full_name
      end
      mark_case_as_sent_step(responded_date: Time.zone.today,
                             expected_status:,
                             expected_to_be_with:)
      logout_step
    end

    def close_case(kase:, user:)
      login_step(user:)
      go_to_case_details_step(kase:)
      close_case_step
    end

    def close_sar_case(kase:, user:, timeliness:, tmm: false)
      login_step(user:)
      go_to_case_details_step(kase:)
      close_sar_case_step timeliness:, tmm:, editable: !kase.overturned_ico?
    end

    def close_ico_appeal_case(kase:, user:, timeliness:, decision:)
      login_step(user:)
      cases_show_page.load(id: kase.id)
      close_ico_appeal_case_step timeliness:, decision:
    end

    def add_message_to_case(kase:, message:, do_logout: true)
      expect(cases_show_page).to be_displayed(id: kase.id)
      cases_show_page.add_message_to_case(message)
      expect(cases_show_page.messages.last).to have_content(message)
      logout_step if do_logout
    end

    def extend_for_pit(kase:, user:, new_deadline:)
      login_step(user:)
      go_to_case_details_step(kase:)
      extend_for_pit_step(kase:, new_deadline:)
      logout_step
    end

    def progress_to_disclosure_step(kase:, user:, do_logout: true)
      login_step(user:)
      go_to_case_details_step(kase:)
      cases_show_page.actions.progress_to_disclosure.click
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.notice)
        .to have_text "The Disclosure team has been notified this case is ready for clearance"
      expect(cases_show_page.case_status.details.copy.text).to eq "Pending clearance"
      logout_step if do_logout
    end

    def search_for(page:, search_phrase:, num_expected_results: nil)
      page.primary_navigation.all_open_cases.click
      expect(open_cases_page).to be_displayed
      open_cases_page.search_query.set search_phrase
      open_cases_page.search_button.click
      unless num_expected_results.nil?
        cases = cases_search_page.case_list
        expect(cases.count).to eq num_expected_results
      end
    end

    def search_for_phrase(page:, search_phrase:, num_expected_results: nil)
      page.search_query.set search_phrase
      page.search_button.click
      unless num_expected_results.nil?
        cases = page.case_list
        expect(cases.count).to eq num_expected_results
      end
    end

    def go_to_case_reassign(expected_users:)
      cases_show_page.actions.reassign_user.click
      unless expected_users.nil?
        expect(reassign_user_page.reassign_to.users.size).to eq expected_users.count
        expected_user_names = expected_users.map do |u|
          if u.respond_to? :full_name
            u.full_name
          else
            u.to_s
          end
          # u.respond_to? :full_name ? u.full_name : u.to_s
        end
        expect(reassign_user_page.reassign_to.users.map(&:text))
          .to match_array expected_user_names
      end
    end

    def do_case_reassign_to(user)
      reassign_user_page.choose_assignment_user user
      reassign_user_page.confirm_button.click

      expect(cases_show_page).to be_displayed
      expect(cases_show_page.case_history.entries.first)
        .to have_text("re-assigned this case to #{user.full_name}")
    end

    def upload_and_approve_response_as_dacu_disclosure_specialist(kase, dd_specialist)
      upload_response_with_action_param(kase, dd_specialist, "upload-approve")
    end

    def upload_response_and_send_for_redraft_as_disclosure_specialist(kase, dd_specialist)
      upload_response_with_action_param(kase, dd_specialist, "upload-redraft")
    end

    def upload_response_with_action_param(kase, user, action)
      uploads_key = "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg"
      is_compliant = true
      rus = ResponseUploaderService.new(
        kase:,
        current_user: user,
        uploaded_files: [uploads_key],
        upload_comment: "I've uploaded it",
        action:,
        is_compliant:,
        bypass_further_approval: false,
        bypass_message: nil,
      )
      uploader = rus.instance_variable_get :@uploader
      allow(uploader).to receive(:move_uploaded_file)
      allow(uploader).to receive(:remove_leftover_upload_files)
      rus.upload!
    end

    def extend_sar_deadline_for(kase:, num_calendar_months:, reason: "The reason for extending")
      cases_show_page.load(id: kase.id)
      cases_show_page.extend_sar_deadline.click

      expect(cases_extend_sar_deadline_page).to be_displayed

      yield(cases_extend_sar_deadline_page) if block_given?

      cases_extend_sar_deadline_page.set_reason_for_extending(reason)
      cases_extend_sar_deadline_page.submit_button.click

      expected_case_history = [
        "Extended SAR deadline",
        reason.to_s,
        " Deadline extended by #{num_calendar_months == 1 ? 'one' : 'two'} calendar #{'month'.pluralize(num_calendar_months)}", # line-break character translates into a space
      ]

      expect(cases_show_page).to be_displayed
      expect(cases_show_page.notice.text).to eq "Case extended for SAR"
      expect(cases_show_page.case_history.rows.first.details.text).to eq(expected_case_history.join)
    end

    def case_deadline_text_to_be(expected_value)
      expect(cases_show_page.case_status.deadlines.final.text).to eq(expected_value)
    end
  end
end
