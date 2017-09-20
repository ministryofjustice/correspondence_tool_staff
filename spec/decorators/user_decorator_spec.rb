require 'rails_helper'

describe CaseDecorator, type: :model do
  let(:disclosure)    { find_or_create(:team_dacu_disclosure) }
  let(:responder)     { create(:responder).decorate }
  let(:sds)           { disclosure.approvers.first.decorate }
  let(:accepted_case) { create(:accepted_case, :flagged_accepted,
                               approver: sds,
                               approving_team: disclosure) }

  describe :full_name_with_optional_load_html do
    it 'returns the users full name if they are not on disclosure team' do
      expect(responder.full_name_with_optional_load_html)
        .to eq responder.full_name
    end

    it 'returns full name with case load info if not disclosure' do
      accepted_case
      expect(sds.full_name_with_optional_load_html)
        .to eq "#{sds.full_name} <strong>(1 open cases)</strong>"
    end
  end
end
