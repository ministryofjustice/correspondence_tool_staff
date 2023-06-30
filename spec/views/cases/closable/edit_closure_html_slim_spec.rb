require "rails_helper"

describe "cases/closable/edit_closure.html.slim" do
  context "with a SAR case" do
    let(:closed_sar) { create :closed_sar }

    it "renders the close_form partial" do
      assign(:case, closed_sar.decorate)
      render
      expect(response)
        .to have_rendered(
          partial: "cases/sar/close_form",
          locals: {
            kase: closed_sar,
            form_url: polymorphic_path(closed_sar, action: :update_closure),
            submit_button: "Save changes",
          },
        )
    end
  end
end
