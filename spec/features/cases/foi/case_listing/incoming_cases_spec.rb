require "rails_helper"

feature "listing incoming on the system" do
  given(:disclosure_specialist) { find_or_create :disclosure_specialist }
  given(:press_officer) { find_or_create :press_officer }
  given(:private_officer) { find_or_create :private_officer }

  given(:assigned_case) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :assigned_case,
             created_at: 1.business_days.ago,
             identifier: "assigned_case"
    end
  end
  given(:fresh_assigned_case) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :assigned_case,
             identifier: "fresh_assigned_case"
    end
  end
  given(:assigned_case_flagged_for_dacu_disclosure) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :assigned_case,
             :flagged,
             created_at: 2.business_days.ago,
             identifier: "assigned_case_flagged_for_dacu_disclosure"
    end
  end
  given(:assigned_case_flagged_for_dacu_disclosure_accepted) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :assigned_case,
             :flagged_accepted,
             created_at: 2.business_days.ago,
             identifier: "assigned_case_flagged_for_dacu_disclosure_accepted"
    end
  end
  given(:assigned_case_flagged_for_press_office_accepted) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :assigned_case,
             :flagged_accepted,
             :press_office,
             created_at: 2.business_days.ago,
             identifier: "assigned_case_flagged_for_press_office_accepted"
    end
  end
  given(:assigned_cr_case_flagged_for_press_office_accepted) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :awaiting_responder_compliance_review,
             :flagged_accepted,
             :press_office,
             created_at: 2.business_days.ago,
             identifier: "assigned_cr_case_flagged_for_press_office_accepted"
    end
  end

  given(:assigned_case_flagged_for_private_office_accepted) do
    Timecop.freeze(Date.new(2020, 8, 19)) do
      create :assigned_case,
             :flagged_accepted,
             :private_office,
             created_at: 2.business_days.ago,
             identifier: "assigned_case_flagged_for_private_office_accepted"
    end
  end

  context "with cases setup for dacu disclosure" do
    background do
      assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_dacu_disclosure_accepted
      assigned_case_flagged_for_press_office_accepted
    end

    scenario "for dacu disclosure" do
      login_as disclosure_specialist

      visit "/cases/incoming"

      cases = incoming_cases_page.case_list

      expect(cases.count).to eq 1
      expect(cases.first.number)
        .to have_text assigned_case_flagged_for_dacu_disclosure.number
    end
  end

  context "with cases setup for press office" do
    given(:too_old_assigned_case) do
      Timecop.freeze(Date.new(2020, 8, 19)) do
        create(:assigned_case,
               created_at: 4.business_days.ago,
               identifier: "too_old_assigned_case")
      end
    end

    background do
      too_old_assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_press_office_accepted
      assigned_cr_case_flagged_for_press_office_accepted
      assigned_case
      fresh_assigned_case
    end

    scenario "for press office" do
      Timecop.freeze(Date.new(2020, 8, 19)) do
        login_as press_officer

        visit "/cases/incoming"

        cases = incoming_cases_page.case_list

        expect(cases.count).to eq 2
        expect(cases.first.number).to have_text assigned_case.number
        expect(cases.second.number)
          .to have_text assigned_case_flagged_for_dacu_disclosure.number
      end
    end
  end

  context "with cases setup for private office" do
    given(:too_old_assigned_case) do
      Timecop.freeze(Date.new(2020, 8, 19)) do
        create :assigned_case,
               created_at: 4.business_days.ago,
               identifier: "too_old_assigned_case"
      end
    end

    background do
      too_old_assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_private_office_accepted
      assigned_case
      fresh_assigned_case
    end

    scenario "for press office" do
      Timecop.freeze(Date.new(2020, 8, 19)) do
        login_as private_officer

        visit "/cases/incoming"

        cases = incoming_cases_page.case_list

        expect(cases.count).to eq 2
        expect(cases.first.number).to have_text assigned_case.number
        expect(cases.second.number)
            .to have_text assigned_case_flagged_for_dacu_disclosure.number
      end
    end
  end
end
