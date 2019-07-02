require 'rails_helper'

RSpec.describe Cases::IcoSarController, type: :controller do
  describe '#new' do
    let(:case_types) { %w[Case::ICO::FOI Case::ICO::SAR] }

    let(:params) {{ correspondence_type: 'ico' }}

    include_examples 'new case spec', Case::ICO::SAR
  end
end
