require "rails_helper"

describe 'cases/overturned_shared/_new.html.slim' do
  let(:bmt_manager) { create(:disclosure_bmt_user) }
  let(:ico_appeal)  { create(:closed_ico_sar_case) }

  let(:overturned_foi) { find_or_create(:overturned_foi_correspondence_type) }

  let(:partial) do
    render
    overturned_ico_new_form_section(rendered)
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:all) do
    @overturned_foi_case = build(:overturned_ico_foi)
  end

  after(:all) do
    DbHousekeeping.clean
  end

  before(:each) do
    assign(:case, @overturned_foi_case.decorate)
    assign(:correspondence_type, overturned_foi)
    assign(:correspondence_type_key, 'overturned_foi')

    login_as bmt_manager
  end

  describe 'ico_appeal_info section' do
    subject { partial.ico_appeal_info }

    it { should be_visible }
    it { should have_text(@overturned_foi_case.number) }
    it { should have_text(@overturned_foi_case.subject) }
    it { should have_text('(opens in a new tab)') }
  end

  describe 'date decision was received' do
    it 'has the case received date' do
      expect(partial.received_date.day.value)
        .to eq @overturned_foi_case.received_date.day.to_s
      expect(partial.received_date.month.value)
        .to eq @overturned_foi_case.received_date.month.to_s
      expect(partial.received_date.year.value)
        .to eq @overturned_foi_case.received_date.year.to_s
    end
  end

  describe 'final deadline' do
    it 'is blank' do
      expect(partial.final_deadline.day.value).to eq ''
      expect(partial.final_deadline.month.value).to eq ''
      expect(partial.final_deadline.year.value).to eq ''
    end
  end

  describe "requester's email" do
    it "populates from the case" do
      expect(partial).to have_field("Requester's email",
                                    with: @overturned_foi_case.email,
                                    type: :email)
    end
  end

  describe "requester's postal address" do
    it "populates from the case" do
      expect(partial).to have_field("Requester's postal address",
                                    with: @overturned_foi_case.postal_address,
                                    type: :textarea)
    end
  end

  describe "reply method" do
    it "populates from the case" do
      expect(partial).to have_checked_field("By email")
    end
  end

  describe 'ico officer name' do
    it 'populates from the case' do
      expect(partial)
        .to have_field(
              "Name of the ICO information officer who's handling this case",
              with: @overturned_foi_case.ico_officer_name,
              type: :text
            )
    end
  end
end
