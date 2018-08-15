require 'rails_helper'
require 'thor'

require 'cts'
require 'cts/cases/create'

describe CTS::Cases::Create, tag: :cli do
  let(:cts_creator) { CTS::Cases::Create.new(Rails.logger, case_params) }

  describe '#new_ico_case' do
    context 'new default FOI ICO appeal' do
      let(:case_params) { { type: 'Case::ICO::FOI' } }

      it 'returns a valid new ICO case' do
        foi = create(:rejected_case)
        kase = cts_creator.new_case
        # Please remove this once CTS::Cases::Create is changed to create the
        # original case.
        kase.original_case_id = foi.id
        expect(kase).to be_valid
      end
    end
  end
end
