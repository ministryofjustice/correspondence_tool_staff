# coding: utf-8
require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'editing case closure information' do
  given(:manager) { create :disclosure_bmt_user }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'bmt changes case closure information', js: true do
    kase = create :closed_case

    login_as manager
    cases_show_page.load(id: kase.id)
    edit_foi_case_closure_step(kase: kase,
                               date_responded: 10.business_days.ago)
  end

  scenario 'bmt views case details for FOI with old closure info', js: true do
    kase = create :closed_case
    kase.update_attribute(:info_held_status_id, nil)

    login_as manager
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_details).not_to have_edit_closure
    expect(cases_show_page.case_details)
      .to have_text("This is an old case with closure details that can't be edited")
  end
end
