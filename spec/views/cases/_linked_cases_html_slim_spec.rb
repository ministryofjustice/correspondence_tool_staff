require 'rails_helper'

describe 'cases/linked_cases.html.slim', type: :view do

  def allow_case_policy(policy_name, kase)
    policy = double('Pundit::Policy', policy_name => true)
    allow(view).to receive(:policy).with(kase).and_return(policy)
  end

  def disallow_case_policy(policy_name, kase)
    policy = double('Pundit::Policy', policy_name => false)
    allow(view).to receive(:policy).with(kase).and_return(policy)
  end


  describe 'Case has linked cases' do
    let(:linked_case_1){ double(Case::Base, id: 1,
                                number: '111111',
                                name:'Hello 1',
                                subject: 'Case 1',
                                trigger_case_marker: '',
                                linked_cases: [])}
    let(:linked_case_2){ double(Case::Base, id: 2,
                                number: '222222',
                                subject: 'Case 2',
                                name:'Hello 2', linked_cases: [])}
    let(:main_case)    { double(Case::Base, id: 3,
                                number: '333333',
                                name:'Hello',
                                subject: 'Case 3',
                                trigger_case_marker: '',
                                linked_cases: [linked_case_1,
                                               linked_case_2 ])}


    it 'displays the initial case details' do

      disallow_case_policy :new_case_link?, main_case

      render partial: 'cases/linked_cases.html.slim',
             locals:{ case_details: main_case}
      
      partial = linked_cases_section(rendered)

      expect(partial.section_heading.text).to eq 'Linked cases'

      main_case.linked_cases.each_with_index do | linked_case, index|
        row = partial.linked_records[index]
        expect(row.link).to have_link("Link to case #{linked_case.number}", href: case_path(linked_case.id))
        expect(row.case_type.text).to eq 'FOI '
        expect(row.request.text)
            .to eq "#{ linked_case.subject } #{ linked_case.name }"
      end
    end
  end

  describe 'Case with no linked cases' do

    let(:unlinked_case) { instance_double(Case::Base, name:'Hello', linked_cases: [])}

    it 'renders "No linked cases"' do

      disallow_case_policy :new_case_link?, unlinked_case

      render partial: 'cases/linked_cases.html.slim',
             locals:{ case_details: unlinked_case}

      partial = linked_cases_section(rendered)

      expect(partial.section_heading.text).to eq 'Linked cases'

      expect(partial.linked_records.first.no_linked_cases.text)
          .to eq 'No linked cases'
    end

  end

  describe 'displaying "Link a case" action' do

    let(:main_case)    { double(Case::Base, id: 3,
                                number: '333333',
                                name:'Hello',
                                subject: 'Case 3',
                                trigger_case_marker: '',
                                linked_cases: [])}

    it 'hides the link if user is not authorised to link cases' do
      disallow_case_policy :new_case_link?, main_case

      render partial: 'cases/linked_cases.html.slim',
             locals:{ case_details: main_case}

      partial = linked_cases_section(rendered)

      expect(partial).to have_no_action_link
    end

    it 'shows the link if user is authorised to link cases' do
      allow_case_policy :new_case_link?, main_case

      render partial: 'cases/linked_cases.html.slim',
             locals:{ case_details: main_case}

      partial = linked_cases_section(rendered)

      expect(partial).to have_action_link
      expect(partial.action_link.text).to eq 'Link a case'

      expect(partial.action_link.native[:href])
          .to eq new_case_link_case_path(main_case.id)

    end
  end

end
