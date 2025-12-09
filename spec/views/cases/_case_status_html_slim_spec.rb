require "rails_helper"

describe "cases/case_status.html.slim", type: :view do
  it "displays the all 4 key information " do
    unassigned_case = double Case::BaseDecorator, # rubocop:disable RSpec/VerifiedDoubles
                             status: "Needs reassigning",
                             ico?: false,
                             internal_deadline: Time.zone.now.strftime(Settings.default_date_format),
                             external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
                             current_state: "drafting",
                             type_abbreviation: "FOI",
                             who_its_with: "DACU",
                             type_of_offender_sar?: false,
                             offender_sar?: false,
                             stopped?: false

    render partial: "cases/case_status", locals: { case_details: unassigned_case }

    partial = case_status_section(rendered)

    expect(partial.details.copy_label.text).to eq "Status"
    expect(partial.details.copy.text).to eq unassigned_case.status
    expect(partial.details.who_its_with_label.text).to eq "With"
    expect(partial.details.who_its_with.text)
        .to eq unassigned_case.who_its_with

    expect(partial.deadlines.draft_label.text).to eq "Draft deadline"
    expect(partial.deadlines.draft.text)
        .to eq unassigned_case.internal_deadline
    expect(partial.deadlines.final_label.text).to eq "Final deadline"
    expect(partial.deadlines.final.text)
        .to eq unassigned_case.external_deadline
  end

  it 'does not display "Who its with" for closed cases' do
    closed_case = double Case::BaseDecorator, # rubocop:disable RSpec/VerifiedDoubles
                         status: "Closed",
                         ico?: false,
                         internal_deadline: Time.zone.now.strftime(Settings.default_date_format),
                         external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
                         current_state: "closed",
                         type_abbreviation: "FOI",
                         who_its_with: "",
                         type_of_offender_sar?: false,
                         offender_sar?: false,
                         stopped?: false

    render partial: "cases/case_status",
           locals: { case_details: closed_case }

    partial = case_status_section(rendered)

    expect(partial.details.copy.text).to eq closed_case.status
    expect(partial.details).to have_no_who_its_with

    expect(partial.deadlines.draft.text)
        .to eq closed_case.internal_deadline
    expect(partial.deadlines.final.text)
        .to eq closed_case.external_deadline
  end

  it "does not display Draft deadline for non-trigger cases" do
    non_trigger_case = double Case::BaseDecorator, # rubocop:disable RSpec/VerifiedDoubles
                              status: "Needs reassigning",
                              external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
                              ico?: false,
                              internal_deadline: nil,
                              current_state: "drafting",
                              type_abbreviation: "FOI",
                              who_its_with: "DACU",
                              type_of_offender_sar?: false,
                              offender_sar?: false,
                              stopped?: false

    render partial: "cases/case_status",
           locals: { case_details: non_trigger_case }

    partial = case_status_section(rendered)

    expect(partial.details.copy.text).to eq non_trigger_case.status
    expect(partial.details.who_its_with.text)
        .to eq non_trigger_case.who_its_with

    expect(partial.deadlines).to have_no_draft
    expect(partial.deadlines.final.text)
        .to eq non_trigger_case.external_deadline
  end

  describe "ICO case reference number" do
    let(:ico_overturned_sar) do
      double Case::OverturnedICO::SARDecorator, # rubocop:disable RSpec/VerifiedDoubles
             status: "Needs reassigning",
             external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
             ico_reference_number: "123456789ABC",
             ico?: true,
             internal_deadline: nil,
             current_state: "drafting",
             type_abbreviation: "OVERTURNED_SAR",
             who_its_with: "DACU",
             type_of_offender_sar?: false,
             offender_sar?: false,
             stopped?: false
    end

    it "does not show ICO case reference number for foi cases" do
      non_trigger_case = double Case::BaseDecorator, # rubocop:disable RSpec/VerifiedDoubles
                                status: "Needs reassigning",
                                external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
                                ico?: false,
                                internal_deadline: nil,
                                current_state: "drafting",
                                type_abbreviation: "FOI",
                                who_its_with: "DACU",
                                type_of_offender_sar?: false,
                                offender_sar?: false,
                                stopped?: false

      render partial: "cases/case_status",
             locals: { case_details: non_trigger_case }

      partial = case_status_section(rendered)

      expect(partial.details.copy.text).to eq non_trigger_case.status
      expect(partial.details.who_its_with.text)
          .to eq non_trigger_case.who_its_with

      expect(partial.deadlines).to have_no_draft
      expect(partial.deadlines.final.text)
          .to eq non_trigger_case.external_deadline

      expect(partial.details).to have_no_ico_ref_number_label
      expect(partial.details).to have_no_ico_ref_number
    end

    it "displays ICO case reference number for ico appeal cases" do
      ico_case = double Case::ICO::BaseDecorator, # rubocop:disable RSpec/VerifiedDoubles
                        status: "Needs reassigning",
                        external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
                        ico_reference_number: "123456789ABC",
                        ico?: true,
                        internal_deadline: nil,
                        current_state: "drafting",
                        type_abbreviation: "ICO",
                        who_its_with: "DACU",
                        type_of_offender_sar?: false,
                        offender_sar?: false,
                        stopped?: false

      render partial: "cases/case_status",
             locals: { case_details: ico_case }

      partial = case_status_section(rendered)

      expect(partial.details.copy.text).to eq ico_case.status
      expect(partial.details.who_its_with.text)
          .to eq ico_case.who_its_with

      expect(partial.deadlines).to have_no_draft
      expect(partial.deadlines.final.text)
          .to eq ico_case.external_deadline

      expect(partial.details.ico_ref_number_label.text).to eq "ICO case reference number"
      expect(partial.details.ico_ref_number.text).to eq ico_case.ico_reference_number
    end

    it "displays the page counts for Offender SAR cases" do
      params = {
        status: "Needs reassigning",
        external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
        ico?: false,
        internal_deadline: nil,
        current_state: "drafting",
        type_abbreviation: "ICO",
        who_its_with: "Branston Registry",
        type_of_offender_sar?: false,
        offender_sar_complaint?: false,
        offender_sar?: false,
        rejected?: false,
        page_count: "500",
        number_exempt_pages: "200",
        number_final_pages: "250",
        stopped?: false,
      }
      offender_sar_case = double Case::SAR::OffenderDecorator, # rubocop:disable RSpec/VerifiedDoubles
                                 params.merge({ type_of_offender_sar?: true })
      offender_sar_complaint = double Case::SAR::OffenderComplaintDecorator, # rubocop:disable RSpec/VerifiedDoubles
                                      params.merge({ offender_sar_complaint?: true })

      [offender_sar_case, offender_sar_complaint].each do |kase|
        render partial: "cases/case_status",
               locals: { case_details: kase }
        partial = case_status_section(rendered)

        expect(partial.details.page_counts.received_label.text).to eq "Pages received"
        expect(partial.details.page_counts.received_number.text).to eq "500"
        expect(partial.details.page_counts.exempt_label.text).to eq "Exempt pages"
        expect(partial.details.page_counts.exempt_number.text).to eq "200"
        expect(partial.details.page_counts.dispatched_label.text).to eq "Final page count"
        expect(partial.details.page_counts.dispatched_number.text).to eq "250"
      end
    end

    it "does not display the page counts for rejected Offender Sar cases" do
      params = {
        status: "Needs reassigning",
        external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
        ico?: false,
        internal_deadline: nil,
        current_state: "drafting",
        type_abbreviation: "ICO",
        who_its_with: "Branston Registry",
        type_of_offender_sar?: false,
        offender_sar_complaint?: false,
        offender_sar?: false,
        rejected?: true,
        page_count: "500",
        number_exempt_pages: "200",
        number_final_pages: "250",
        stopped?: false,
      }
      kase = double Case::SAR::OffenderDecorator, # rubocop:disable RSpec/VerifiedDoubles
                    params.merge({ type_of_offender_sar?: true })

      render partial: "cases/case_status",
             locals: { case_details: kase }
      partial = case_status_section(rendered)

      expect(partial.details).to have_no_page_counts
    end

    it "does not display Page counts for non-offender SAR case" do
      ico_case = double Case::ICO::BaseDecorator, # rubocop:disable RSpec/VerifiedDoubles
                        status: "Needs reassigning",
                        external_deadline: (Time.zone.now + 10.days).strftime(Settings.default_date_format),
                        ico_reference_number: "123456789ABC",
                        ico?: true,
                        internal_deadline: nil,
                        current_state: "drafting",
                        type_abbreviation: "ICO",
                        who_its_with: "DACU",
                        type_of_offender_sar?: false,
                        offender_sar?: false,
                        stopped?: false

      render partial: "cases/case_status",
             locals: { case_details: ico_case }

      partial = case_status_section(rendered)

      expect(partial.details).to have_no_page_counts
    end

    it "displays ICO case reference number for ICO overturned SAR cases" do
      render partial: "cases/case_status",
             locals: { case_details: ico_overturned_sar }
      partial = case_status_section(rendered)

      expect(partial.details.ico_ref_number_label.text)
        .to eq "ICO case reference number"
      expect(partial.details.ico_ref_number.text).to eq "123456789ABC"
    end
  end

  describe "stop the clock" do
    context "when Standard SAR case is stopped" do
      let(:sar) { create :sar_case, :stopped }
      let(:decorated_case) { Case::SAR::StandardDecorator.new(sar) }

      it "displays paused deadlines" do
        render partial: "cases/case_status", locals: { case_details: decorated_case }
        partial = case_status_section(rendered)

        expect(partial.deadlines.text).not_to include "Draft deadline (paused)"
        expect(partial.deadlines.final_label.text).to eq "Final deadline (paused)"
        expect(partial.deadlines.final.text).to eq decorated_case.external_deadline
      end
    end

    context "when Flagged SAR case is stopped" do
      let(:sar) { create :sar_case, :flagged, :stopped }
      let(:decorated_case) { Case::SAR::StandardDecorator.new(sar) }

      it "displays paused deadlines" do
        render partial: "cases/case_status", locals: { case_details: decorated_case }
        partial = case_status_section(rendered)

        expect(partial.deadlines.draft_label.text).to eq "Draft deadline (paused)"
        expect(partial.deadlines.draft.text).to eq decorated_case.internal_deadline
        expect(partial.deadlines.final_label.text).to eq "Final deadline (paused)"
        expect(partial.deadlines.final.text).to eq decorated_case.external_deadline
      end
    end
  end
end
