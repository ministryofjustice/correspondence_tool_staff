require "rails_helper"

describe "cases/case_attachments.html.slim", type: :view do
  def allow_case_policy(policy_name, kase)
    policy = double("Pundit::Policy", policy_name => true)
    allow(view).to receive(:policy).with(kase).and_return(policy)
  end

  def disallow_case_policy(policy_name, kase)
    policy = double("Pundit::Policy", policy_name => false)
    allow(view).to receive(:policy).with(kase).and_return(policy)
  end

  let(:kase) { create :case_with_response }

  before do
    upload_group_1 = "20170608101112"
    upload_group_2 = "20170612114201"
    responder_1 = kase.responding_team.users.first
    responder_2 = kase.responding_team.users.last

    kase.attachments.first.update!(upload_group: upload_group_1, user_id: responder_1.id)

    2.times do
      kase.attachments << create(:correspondence_response, upload_group: upload_group_1, user_id: responder_1.id)
    end

    2.times do
      kase.attachments << create(:correspondence_response, upload_group: upload_group_2, user_id: responder_2.id)
    end
  end

  describe "section heading" do
    let(:ico_case) { create :ico_foi_case_with_response }

    it "displays as Appeal response for ICO cases" do
      disallow_case_policy(:can_remove_attachment?, ico_case)

      render partial: "cases/case_attachments",
             locals: { case_details: ico_case }

      partial = case_attachments_section(rendered)
      expect(partial.section_heading.text).to eq "Appeal response"
    end

    it "displays as Response for non ICO cases" do
      disallow_case_policy(:can_remove_attachment?, kase)

      render partial: "cases/case_attachments",
             locals: { case_details: kase }

      partial = case_attachments_section(rendered)

      expect(partial.section_heading.text).to eq "Response"
    end
  end

  describe "filename" do
    it "displays a filename" do
      disallow_case_policy(:can_remove_attachment?, kase)

      render partial: "cases/case_attachments",
             locals: { case_details: kase }

      partial = case_attachments_section(rendered)

      partial.collection.each_with_index do |row, index|
        expect(row.filename.text).to eq kase.attachments[index].filename
      end
    end
  end

  describe "#actions" do
    it "has a preview and download link" do
      disallow_case_policy(:can_remove_attachment?, kase)

      render partial: "cases/case_attachments",
             locals: { case_details: kase }

      partial = case_attachments_section(rendered)

      partial.collection.each do |row|
        expect(row.actions).to have_view
        expect(row.actions).to have_download
      end
    end

    describe "#remove" do
      it "shows a remove link if the user is authorised to do so" do
        allow_case_policy(:can_remove_attachment?, kase)

        render partial: "cases/case_attachments",
               locals: { case_details: kase }

        partial = case_attachments_section(rendered)

        partial.collection.each do |row|
          expect(row.actions).to have_remove
        end
      end

      it "does not show a remove link if the user is not allowed to" do
        disallow_case_policy(:can_remove_attachment?, kase)

        render partial: "cases/case_attachments",
               locals: { case_details: kase }

        partial = case_attachments_section(rendered)

        partial.collection.each do |row|
          expect(row.actions).to have_no_remove
        end
      end
    end
  end
end
