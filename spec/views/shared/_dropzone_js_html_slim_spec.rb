require "rails_helper"

describe "shared/dropzone_js.html.slim", type: :view do
  describe "Preview template" do
    it "displays a filename" do
      partial =  render_partial
      expect(partial).to have_filename
    end

    it "displays a file size" do
      partial =  render_partial
      expect(partial).to have_filesize
    end

    it "displays a progressbar" do
      partial =  render_partial
      expect(partial).to have_progressbar
    end

    it "displays a remove link" do
      partial =  render_partial
      expect(partial).to have_remove_link
    end

    it "has a container for error messages" do
      partial = render_partial
      expect(partial).to have_error_message_container
    end
  end

  def render_partial
    render partial: "shared/dropzone_js"
    dropzonejs_preview_template_section(rendered)
  end
end
