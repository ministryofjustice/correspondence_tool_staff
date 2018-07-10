require 'rails_helper'

describe Case::ICO::SAR do
  let(:kase) { described_class.new() }

  describe '.decorator_class' do
    subject { described_class.decorator_class }
    it { should eq Case::ICO::SARDecorator }
  end

  describe '#original_case_type' do
    subject { kase.original_case_type }
    it { should eq 'SAR' }
  end
end
