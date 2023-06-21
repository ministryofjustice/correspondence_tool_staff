require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe "cases/overturned_shared/_new.html.slim" do
  let(:bmt_manager)    { find_or_create(:disclosure_bmt_user) }
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
    @overturned_foi = build_stubbed(:overturned_ico_foi)
  end

  after(:all) do
    # Cleans up objects created in before(:all)
    DbHousekeeping.clean
  end

  before do
    assign(:case, overturned_foi.decorate)
    assign(:correspondence_type, overturned_foi)
    assign(:correspondence_type_key, "overturned_foi")

    login_as bmt_manager
  end

  describe "hidden case info fields" do
    it "has a hidden correspondence_type field" do
      expect(partial.correspondence_type.value).to eq "overturned_foi"
    end

    it "has a hidden original_ico_appeal_id field" do
      expect(partial.original_ico_appeal_id.value).to eq ico_appeal.id.to_s
    end
  end

  describe "ico_appeal_info section" do
    subject { partial.ico_appeal_info }

    it { is_expected.to be_visible }
    it { is_expected.to have_text(overturned_foi.original_ico_appeal.number) }
    it { is_expected.to have_text(overturned_foi.subject) }
    it { is_expected.to have_text("(opens in a new tab)") }

    it "opens up a new tab" do
      link = subject.find("a")
      expect(link[:target]).to eq "_blank"
    end
  end

  describe "final deadline" do
    it "is blank" do
      expect(partial.final_deadline.day.value).to eq ""
      expect(partial.final_deadline.month.value).to eq ""
      expect(partial.final_deadline.year.value).to eq ""
    end
  end

  describe "requester's email" do
    it "populates from the case" do
      expect(partial.has_field?("Requester's email",
                                with: overturned_foi.email,
                                type: :email)).to eq true
    end
  end

  describe "requester's postal address" do
    it "populates from the case" do
      expect(partial.has_field?("Requester's postal address",
                                with: overturned_foi.postal_address,
                                type: :textarea)).to eq true
    end
  end

  describe "reply method" do
    it "populates from the case" do
      expect(partial.has_checked_field?("By email")).to eq true
    end
  end

  describe "ico officer name" do
    it "populates from the case" do
      expect(partial.has_field?(
               "Name of the ICO information officer who's handling this case",
               with: overturned_foi.ico_officer_name,
               type: :text,
             )).to eq true
    end
  end

  describe "back to case details link" do
    it "exists on the page" do
      expect(partial.has_link?("Back to case details", href: "/cases/#{ico_appeal.id}"))
        .to eq true
    end
  end

  describe "flag for disclosure details" do
    it "exists on the page" do
      expect(partial).to have_flag_for_disclosure_specialists
    end

    context "when the original case was flagged" do
      before do
        overturned_foi.flag_for_disclosure_specialists = "yes"
        assign(:case, overturned_foi.decorate)
      end

      it "checks the yes button if the original case is flagged?" do
        expect(partial.flag_for_disclosure_specialists.yes).to be_checked
      end
    end

    context "when the original case was not flagged" do
      before do
        overturned_foi.flag_for_disclosure_specialists = nil
        assign(:case, overturned_foi.decorate)
      end

      it "displays both yes and no unchecked" do
        expect(partial.flag_for_disclosure_specialists.yes).not_to be_checked
        expect(partial.flag_for_disclosure_specialists.no).not_to be_checked
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll, RSpec/BeforeAfterAll
