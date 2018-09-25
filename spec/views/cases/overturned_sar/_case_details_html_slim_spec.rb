require 'rails_helper'

describe 'cases/overturned_sar/case_details.html.slim', type: :view do
  let(:unassigned_case) { create(:overturned_ico_sar) }
  let(:closed_case)     { create(:closed_ot_ico_sar) }
  let(:bmt_manager)     { create(:disclosure_bmt_user) }

  def render_partial(kase)
    render partial: 'cases/overturned_sar/case_details.html.slim',
           locals: { case_details: kase.decorate,
                     link_type: nil }
    overturned_sar_case_details_section(rendered)
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as bmt_manager }

  describe 'basic_details' do
    it 'displays the initial case details (non third party case' do
      partial = render_partial(unassigned_case)

      expect(partial.section_heading.text).to eq 'Case details'

      expect(partial.case_type).to have_no_trigger
      expect(partial.case_type.type.text)
        .to eq "ICO overturned (SAR)  "
      expect(partial.date_received.text)
        .to eq I18n.l(unassigned_case.received_date)
      expect(partial.final_deadline.text)
        .to eq I18n.l(unassigned_case.external_deadline)
    end

    # Requester email/postal address isn't being displayed yet, but once
    # implemented these tests will be needed.
    xit 'does not display the email address if one is not provided' do
      unassigned_case.email = nil
      unassigned_case.postal_address = "1 High Street\nAnytown\nAT1 1AA"
      unassigned_case.reply_method = 'send_by_post'

      partial = render_partial(unassigned_case)

      expect(partial.response_address.text)
        .to eq "1 High Street\nAnytown\nAT1 1AA"
    end

    xit 'does not display the postal address if one is not provided' do
      unassigned_case.postal_address = nil
      unassigned_case.email = 'john.doe@moj.com'

      partial = render_partial(unassigned_case)

      expect(partial).to have_response_address
      expect(partial.response_address.text).to eq 'john.doe@moj.com'
    end
  end

  describe 'closure info' do
    it 'displays the date responded' do
      partial = render_partial(closed_case)

      expect(partial.date_responded.text)
        .to eq closed_case.date_responded.strftime(
                 Settings.default_date_format
               )
    end

    context 'late response' do
      it 'displays that the response was sent late' do
        closed_case.update(
          date_responded: 1.business_day.after(closed_case.external_deadline)
        )

        partial = render_partial(closed_case)

        expect(partial.timeliness.text).to eq 'Answered late'
      end
    end

    context 'on-time response' do
      it 'displays that the response was sent on time' do
        partial = render_partial(closed_case)

        expect(partial.timeliness.text).to eq 'Answered in time'
      end
    end

    it 'displays the time taken to send the response' do
      Timecop.freeze(Time.local(2018, 9, 23, 10, 0, 0)) do
        closed_case.update(
          date_responded: 1.business_day.after(closed_case.external_deadline)
        )
        partial = render_partial(closed_case)

        expect(partial.time_taken.text).to eq '21 working days'
      end
    end
  end

  # Not currently on the details page, will be added later.
  xdescribe 'original case details' do
    let(:ico_case) { create :ico_sar_case}

    it 'displays as original case' do
      assign(:case, ico_case)
      render partial: 'cases/overturned_sar/case_details.html.slim',
             locals: { case_details: ico_case.original_case.decorate,
                       link_type: 'original' }

      partial = case_details_section(rendered)
      expect(partial.original_section_heading.text).to eq "Original case details"
    end

    it 'displays a link to original case' do
      assign(:case, ico_case)
      render partial: 'cases/overturned_sar/case_details.html.slim',
             locals: { case_details: ico_case.original_case.decorate,
                       link_type: nil }

      partial = case_details_section(rendered)
      expect(partial).to have_view_original_case_link
    end

  end


end
