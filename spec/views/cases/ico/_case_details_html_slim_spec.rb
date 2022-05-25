require 'rails_helper'

describe 'cases/ico/case_details.html.slim', type: :view do
  let(:ico_foi_case)      { (create :ico_foi_case).decorate }
  let(:ico_sar_case)      { (create :ico_sar_case).decorate }
  let(:accepted_case)     { (create :accepted_ico_foi_case).decorate }
  let(:responded_case)    { (create :responded_ico_foi_case).decorate }
  let(:accepted_sar_case) { (create :accepted_ico_sar_case).decorate }
  let(:closed_foi_appeal) { (create :closed_ico_foi_case).decorate }
  let(:closed_sar_appeal) { (create :closed_ico_sar_case).decorate }

  context 'FOI' do

    describe 'edit case link' do
      before do
        assign(:case, ico_foi_case)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: ico_foi_case,
                         link_type: nil }
      end

      it 'displays edit case link' do
        partial = case_details_section(rendered)
        expect(partial).to have_edit_case_link
      end
    end

    describe 'basic_details' do
      it 'displays the initial case details' do
        assign(:case, ico_foi_case)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: ico_foi_case,
                         link_type: nil }

        partial = ico_case_details_section(rendered)
        expect(partial.case_type).to have_ico_trigger
        expect(partial.ico_reference.data.text).to eq ico_foi_case.ico_reference_number
        expect(partial.ico_officer_name.data.text).to eq ico_foi_case.ico_officer_name
        expect(partial.case_type.data.text)
          .to eq "ICO appeal (FOI) This is a Trigger case"
        expect(partial.date_received.data.text)
          .to eq ico_foi_case.received_date.strftime(Settings.default_date_format)
        expect(partial.external_deadline.data.text)
          .to eq ico_foi_case.external_deadline
      end

    end

    describe 'responders details' do
      it 'displays the responders team name' do
        assign(:case, accepted_case)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: accepted_case,
                         link_type: nil }

        partial = case_details_section(rendered).responders_details

        expect(partial).to be_all_there
        expect(partial.team.data.text).to eq accepted_case.responding_team.name
        expect(partial.name.data.text).to eq accepted_case.responder.full_name
      end
    end

    describe 'closure details' do
      it 'displays the date,time taken, timeliness and final outcome' do
        assign(:case, closed_foi_appeal)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: closed_foi_appeal,
                         link_type: nil }

        partial = case_details_section(rendered).response_details

        expect(partial.date_responded.data.text).to eq closed_foi_appeal.date_sent_to_requester
        expect(partial.timeliness.data.text).to eq closed_foi_appeal.timeliness
        expect(partial.time_taken.data.text).to eq closed_foi_appeal.time_taken
        expect(partial.outcome.data.text).to eq "#{closed_foi_appeal.ico_decision.capitalize} by ICO"
      end
    end

    describe 'draft compliance details' do
      it 'displays the date compliant' do
        login_as create(:manager)
        assign(:case, responded_case)

        render partial: 'cases/ico/case_details',
               locals:{ case_details: responded_case,
                        link_type: nil }

        partial = case_details_section(rendered).compliance_details

        expect(partial.compliance_date.data.text).to eq responded_case.date_draft_compliant
        expect(partial.compliant_timeliness.data.text).to eq responded_case.draft_timeliness
      end
    end
  end

  context 'SAR' do

    describe 'edit case link' do
      before do
        assign(:case, ico_sar_case)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: ico_sar_case,
                         link_type: nil }
      end

      it 'displays edit case link' do
        partial = case_details_section(rendered)
        expect(partial).to have_edit_case_link
      end
    end

    describe 'basic_details' do
      it 'displays the initial case details' do
        assign(:case, ico_sar_case)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: ico_sar_case,
                         link_type: nil }

        partial = ico_case_details_section(rendered)
        expect(partial.case_type).to have_ico_trigger
        expect(partial.ico_reference.data.text).to eq ico_sar_case.ico_reference_number
        expect(partial.ico_officer_name.data.text).to eq ico_sar_case.ico_officer_name
        expect(partial.case_type.data.text)
          .to eq "ICO appeal (SAR) This is a Trigger case"
        expect(partial.date_received.data.text)
          .to eq ico_sar_case.received_date.strftime(Settings.default_date_format)
        expect(partial.external_deadline.data.text)
          .to eq ico_sar_case.external_deadline
      end

    end

    describe 'responders details' do
      it 'displays the responders team name' do
        assign(:case, accepted_sar_case)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: accepted_sar_case,
                         link_type: nil }

        partial = case_details_section(rendered).responders_details

        expect(partial).to be_all_there
        expect(partial.team.data.text).to eq accepted_sar_case.responding_team.name
        expect(partial.name.data.text).to eq accepted_sar_case.responder.full_name
      end
    end

    describe 'closure details' do
      it 'displays the date,time taken, timeliness and final outcome' do
        assign(:case, closed_sar_appeal)
        login_as create(:manager)
        render partial: 'cases/ico/case_details',
               locals: { case_details: closed_sar_appeal,
                         link_type: nil }

        partial = case_details_section(rendered).response_details

        expect(partial.date_responded.data.text).to eq closed_sar_appeal.date_sent_to_requester
        expect(partial.timeliness.data.text).to eq closed_sar_appeal.timeliness
        expect(partial.time_taken.data.text).to eq closed_sar_appeal.time_taken
        expect(partial.outcome.data.text).to eq "#{closed_sar_appeal.ico_decision.capitalize} by ICO"
      end
    end

  end

end
