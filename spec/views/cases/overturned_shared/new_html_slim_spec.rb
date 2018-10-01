require "rails_helper"

describe 'cases/overturned_shared/_new.html.slim' do
  let(:bmt_manager)    { create(:disclosure_bmt_user) }
  let(:ico_appeal)     { @overturned_foi.original_ico_appeal }
  let(:overturned_foi) { @overturned_foi }

  let(:partial) do
    render
    overturned_ico_new_form_section(rendered)
  end

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:all) do
    # Creating an Overturned FOI case fixture is slow because it has to create
    # the original cases, etc. Let's only do this once.
    @overturned_foi = build(:overturned_ico_foi)
  end

  after(:all) do
    DbHousekeeping.clean
  end

  before(:each) do
    assign(:case, overturned_foi.decorate)
    assign(:correspondence_type, overturned_foi)
    assign(:correspondence_type_key, 'overturned_foi')

    login_as bmt_manager
  end

  describe 'hidden case info fields' do
    it 'has a hidden correspondence_type field' do
      expect(partial.correspondence_type.value).to eq 'overturned_foi'
    end

    it 'has a hidden original_ico_appeal_id field' do
      expect(partial.original_ico_appeal_id.value).to eq ico_appeal.id.to_s
    end
  end

  describe 'ico_appeal_info section' do
    subject { partial.ico_appeal_info }

    it { should be_visible }
    it { should have_text(overturned_foi.number) }
    it { should have_text(overturned_foi.subject) }
    it { should have_text('(opens in a new tab)') }

    it 'should open up a new tab' do
      link = subject.find('a')
      expect(link[:target]).to eq '_blank'
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
                                    with: overturned_foi.email,
                                    type: :email)
    end
  end

  describe "requester's postal address" do
    it "populates from the case" do
      expect(partial).to have_field("Requester's postal address",
                                    with: overturned_foi.postal_address,
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
              with: overturned_foi.ico_officer_name,
              type: :text
            )
    end
  end
end
