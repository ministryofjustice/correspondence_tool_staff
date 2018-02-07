require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'Closing a sar' do
  let(:responder)   { create :responder }

  background do
    login_as responder
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  context 'Reporting timiliness', js:true do
    context 'tmm responded-to in time' do
      given!(:fully_granted_case) { create :accepted_sar,
                                          received_date: 10.business_days.ago,
                                          responder: responder}

      # given!(:responded_date) { fully_granted_case
      #                                     .responded_transitions.last.created_at}

      scenario 'A KILO has responded and an manager closes the case' do
        open_cases_page.load(timeliness: 'in_time')
        close_case(fully_granted_case)

        cases_respond_page.fill_in_date_responded(0.business_days.ago)
        cases_respond_page.missing_info.yes.click

        cases_respond_page.submit_button.click

        show_page = cases_show_page.case_details

        expect(show_page.response_details.date_responded.data.text)
          .to eq 0.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered in time'
        expect(show_page.response_details.time_taken.data.text)
          .to eq '10 working days'
        expect(show_page.response_details.refusal_reason.data.text)
          .to eq '(s1(3)) - Clarification required'
      end
    end

    context 'not tmm', js:true do
      given!(:fully_granted_case) { create :accepted_sar,
                                          received_date: 10.business_days.ago,
                                          responder: responder}
      scenario 'A KILO has responded and an manager closes the case' do


        open_cases_page.load(timeliness: 'in_time')
        close_case(fully_granted_case)

        cases_respond_page.fill_in_date_responded(0.business_days.ago)
        cases_respond_page.missing_info.no.click
        cases_respond_page.submit_button.click

        show_page = cases_show_page.case_details

        expect(show_page.response_details.date_responded.data.text)
          .to eq 0.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered in time'
        expect(show_page.response_details.time_taken.data.text)
          .to eq '10 working days'
        expect(show_page.response_details).to have_no_refusal_reason
      end
    end

    context 'responded-to late' do
      given!(:late_case) { create :accepted_sar,
                            received_date: 22.business_days.ago,
                            responder: responder }

      scenario 'the case is responded-to late' do
        open_cases_page.load(timeliness: 'late')
        close_case(late_case)

        cases_respond_page.fill_in_date_responded(0.business_days.ago)
        cases_respond_page.missing_info.yes.click
        cases_respond_page.submit_button.click
        show_page = cases_show_page.case_details

        expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered late'
        expect(show_page.response_details.time_taken.data.text)
          .to eq '22 working days'
      end
    end
  end

  private

  def close_case(kase)
    expect(cases_page.case_list.last.status.text).to eq 'Draft in progress'
    click_link kase.number

    cases_show_page.actions.mark_as_sent.click

    # expect(cases_respond_page).to be_displayed(kase.id)
    # expect(cases_show_page.actions).
    #   to have_link('mark_as_sent', href: respond_case_path(kase))
    # click_link 'Mark as sent'
  end
end
