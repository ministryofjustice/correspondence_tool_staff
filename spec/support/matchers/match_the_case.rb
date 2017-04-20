require 'rspec/expectations'

RSpec::Matchers.define :match_the_case do |kase|
  define_method :case_states do
    {
      'unassigned' => 'Allocation',
      'awaiting_dispatch' => 'Awaiting Dispatch',
      'awaiting_responder' => 'Acceptance',
      'awaiting_responder_email' => 'Waiting to be accepted',
      'drafting' => 'Response',
      'responded' => 'Closure',
      'closed' => 'Case closed',
    }
  end

  match do |actual|
    expect(actual.name.text).to eq kase.name
    expect(actual.subject.text).to eq kase.subject
    expect(actual.status.text).to eq case_states[kase.current_state]
    expect(actual.external_deadline.text)
      .to have_content(kase.external_deadline.strftime('%e %b %Y'))
    expect(actual.number)
      .to have_link("#{kase.number}", href: case_path(kase.id))
    expect(actual.who_its_with.text).to eq @with_text if @with_text
  end

  chain :and_be_with do |with_text|
    @with_text = with_text
  end

  failure_message do |actual|
    message = ''
    unless actual.name.text == kase.name
      message += <<EOM
  expected case name: #{kase.name}
       got case name: #{actual.name.text}
EOM
    end
    unless actual.subject.text == kase.subject
      message += <<EOM
  expected case subject: #{kase.subject}
    actual case subject: #{actual.subject.text}
EOM
    end
    unless actual.status.text == case_states[kase.current_state]
      message += <<EOM
  expected case state: #{case_states[kase.current_state]}
    actual case state: #{actual.status.text}
EOM
    end
    unless actual.external_deadline.text
             .include? kase.external_deadline.strftime('%e %b %Y')
      message += <<EOM
  expected case external deadline: #{kase.external_deadline.strftime('%e %b %Y')}
    actual case external deadline: #{actual.external_deadline.text}
EOM
    end
    unless actual.number.has_link? kase.number, href: case_path(kase.id)
      message += <<EOM
  expected case number to be a link to: #{case_path(kase.id)}
EOM
    end
    unless @with_text.nil? || actual.who_its_with.text == @with_text
      message += <<EOM
  expected case to be with: #{@with_text}
       actual case is with: #{actual.who_its_with.text}
EOM
    end
    message
  end
end
