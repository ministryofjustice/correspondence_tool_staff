require 'rails_helper'

describe 'cases/case_request.html.slim', type: :view do
  let(:long_message) {
    "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
        "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney "+
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
        "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " +
        "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " +
        "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."
  }

  let(:short_message) {
    "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
        "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " +
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
        "and going through th"
  }

  let(:last_part){
    "e cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
        "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
        "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
        "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " +
        "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " +
        "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."
  }


  describe 'Displaying a short request' do
    let(:kase) { create(:case_being_drafted,
                        message: "This is a request for information") }
    let(:decorated_case) do
      kase.decorate.tap do |c|
        allow(c).to receive(:message_extract)
                      .and_return(["This is a request for information"])
      end
    end

    let(:partial) do
      render partial: 'cases/case_request.html.slim',
             locals:{ case_details: decorated_case }

      case_request_section(rendered)
    end

    it 'displays the full request for a short request ' do
      expect(partial.message.text).to eq kase.message
    end

    it 'does not have a collapsed request' do
      expect(partial).to have_no_show_more_link
      expect(partial).to have_no_preview
      expect(partial).to have_no_ellipsis
      expect(partial).to have_no_collapsed_text
    end
  end


  describe 'displaying a long request and collapsing content' do
    let(:kase) { create(:case_being_drafted, message: long_message) }
    let(:decorated_case) do
      kase.decorate.tap do |c|
        allow(c).to receive(:message_extract).and_return([short_message,last_part])
      end
    end

    let(:partial) do
      render partial: 'cases/case_request.html.slim',
             locals:{ case_details: decorated_case}

      case_request_section(rendered)
    end

    it 'displays a preview of the full request ' do
      expect(partial.message.text)
          .to_not eq kase.message

      expect(partial).to have_show_more_link
      expect(partial).to have_preview
      expect(partial).to have_ellipsis
    end

  end

  describe 'displays request attachments for postal FOI' do
    let(:sent_by_post) { create :case, :sent_by_post }
    let(:decorated_case) do
      sent_by_post.decorate.tap do |c|
        allow(c).to receive(:message_extract).and_return([sent_by_post.message, ''])
      end
    end

    let(:partial) do
      render partial: 'cases/case_request.html.slim',
             locals:{ case_details: decorated_case }

      case_request_section(rendered)
    end

    it 'should display a download link' do
      expect(partial.attachments.first.collection.first.actions).to have_download
    end

    it 'should not have a delete option' do
      expect(partial.attachments.first.collection.first.actions).to have_no_remove
    end
  end
end
