require 'rspec/expectations'

RSpec::Matchers.define :match_the_case do |kase|
  define_method :case_states do
    {
      'unassigned' => 'Needs reassigning',
      'awaiting_dispatch' => 'Ready to send',
      'awaiting_responder' => 'To be accepted',
      'awaiting_responder_email' => 'Waiting to be accepted',
      'drafting' => 'Draft in progress',
      'responded' => 'Ready to close',
      'closed' => 'Case closed'
    }
  end

  match do |actual|
    expect(actual.request_detail.text).to eq "#{kase.subject}#{kase.name}"
    expect(actual.status.text).to eq case_states[kase.current_state]
    if kase.requires_clearance?
      expect(actual.draft_deadline.text).to have_content(kase.internal_deadline.strftime('%e %b %Y'))
    else
      expect(actual.draft_deadline.text).to eq ''
    end
    expect(actual.external_deadline.text).to have_content(kase.external_deadline.strftime('%e %b %Y'))
    expect(actual.number).to have_link("#{kase.number}", href: case_path(kase.id))
    expect(actual.who_its_with.text).to eq @with_text if @with_text
  end

  chain :and_be_with do |with_text|
    @with_text = with_text
  end

  failure_message do |actual|
    message = ''
    message += request_detail_message(kase, actual) unless actual.request_detail.text == "#{kase.subject}#{kase.name}"
    message += status_message(kase, actual) unless actual.status.text == case_states[kase.current_state]
    message += external_deadline_message(kase, actual) unless actual.external_deadline.text.include? kase.external_deadline.strftime('%e %b %Y')
    message += number_message(kase, actual) unless actual.number.has_link? kase.number, href: case_path(kase.id)
    message += with_message(kase, actual) unless @with_text.nil? || actual.who_its_with.text == @with_text
    if kase.requires_clearance?
      message += draft_deadline_incorrect_message(kase, actual) unless actual.draft_deadline.text.include?(kase.external_deadline.strftime('%e %b %Y'))
    else
      message += draft_deadline_not_blank_message(kase, actual) unless actual.draft_deadline.text == ''
    end
    message
  end

  def request_detail_message(kase, actual)
    <<~EOM
      expected case name: #{kase.subject}#{kase.name}
           got case name: #{actual.request_detail.text}
    EOM
  end

  def status_message(kase, actual)
    <<~EOM
      expected case state: #{case_states[kase.current_state]}
        actual case state: #{actual.status.text}
    EOM
  end

  def external_deadline_message(kase, actual)
    <<~EOM
      expected case external deadline: #{kase.external_deadline.strftime('%e %b %Y')}
        actual case external deadline: #{actual.external_deadline.text}
    EOM
  end

  def number_message(kase, _actual)
    <<~EOM
      expected case number to be a link to: #{case_path(kase.id)}
    EOM
  end

  def with_message(_kase, actual)
    <<~EOM
      expected case to be with: #{@with_text}
           actual case is with: #{actual.who_its_with.text}
    EOM
  end

  def draft_deadline_incorrect_message(kase, actual)
    <<~EOM
        expected case draft deadline: #{kase.internal_deadline.strftime('%e %b %Y')}
          actual case internal deadline: #{actual.draft_deadline.text}
    EOM
  end

  def draft_deadline_not_blank_message(kase, actual)
    <<~EOM
      expected case draft deadline: #{kase.internal_deadline.strftime('%e %b %Y')}
        actual case internal deadline: #{actual.draft_deadline.text}
    EOM
  end
end
