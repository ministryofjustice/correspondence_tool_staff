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
                                          received_date: 7.business_days.ago,
                                          responder: responder}


      scenario 'A KILO has responded and closes the case' do
        open_cases_page.load

        go_to_case_details_step kase: fully_granted_case

        close_sar_case tmm: true
      end
    end

    context 'not tmm', js:true do
      given!(:fully_granted_case) { create :accepted_sar,
                                          received_date: 7.business_days.ago,
                                          responder: responder}
      scenario 'A KILO has responded and an manager closes the case' do
        open_cases_page.load

        go_to_case_details_step kase: fully_granted_case

        close_sar_case
      end
    end

    context 'responded-to late' do
      given!(:late_case) { create :accepted_sar,
                            received_date: 50.business_days.ago,
                            responder: responder }

      scenario 'the case is responded-to late' do

        open_cases_page.load

        go_to_case_details_step kase: late_case

        close_sar_case timeliness: 'late',
                       time_taken: 50
      end
    end
  end
end
