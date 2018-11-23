require 'rails_helper'

describe 'shared/dropzone_js.html.slim', type: :view do
  def render_partial(locals: {})
    render partial: 'shared/dropzone_form.html.slim', locals: locals
    dropzone_form_section(rendered)
  end

  let(:locals) do
    {
      s3_direct_post:
        S3Uploader.s3_direct_post_for_case(kase, :request),
      accepted_case_attachment_types:
        Settings.case_uploads_accepted_types.join(','),
      file_input_name: 'upload_file',
      case_id: kase.id,
    }
  end

  context 'with a new case' do
    let(:kase) { build(:foi_case) }

    it 'renders case attachments path', js: true do
      partial = render_partial(locals: locals)
      expect(partial.container[:'data-process-file-url'])
        .to eq '/case_attachments'
    end
  end

  context 'with an existing case' do
    let(:kase) { create(:case_being_drafted) }

    it 'renders case attachments path', js: true do
      partial = render_partial(locals: locals)
      expect(partial.container[:'data-process-file-url'])
        .to eq "/cases/#{kase.id}/attachments"
    end
  end

  describe 'data-attachment-type attribute' do
    context 'without attachment_type set' do
      let(:kase) { create(:case_being_drafted) }

      it 'defaults to "response"' do
        partial = render_partial(locals: locals)
        expect(partial.container[:'data-attachment-type'])
          .to eq 'response'
      end
    end

    context 'with attachment_type set' do
      let(:kase) { create(:case_being_drafted) }

      it 'defaults to "response"' do
        partial = render_partial(
          locals: locals.merge(attachment_type: 'request')
        )
        expect(partial.container[:'data-attachment-type'])
          .to eq 'request'
      end
    end
  end

  describe 'data-correspondence-type attribute' do
    context 'without correspondence_type set' do
      let(:kase) { create(:case_being_drafted) }

      it 'defaults to nil' do
        partial = render_partial(locals: locals)
        expect(partial.container[:'data-correspondenc-type']).to be_nil
      end
    end

    context 'with correspondence_type set' do
      let(:kase) { create(:case_being_drafted) }

      it 'defaults to "response"' do
        partial = render_partial(
          locals: locals.merge(correspondence_type: 'foi')
        )
        expect(partial.container[:'data-correspondence-type']).to eq 'foi'
      end
    end
  end
end
