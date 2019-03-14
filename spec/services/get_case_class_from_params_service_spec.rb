require 'rails_helper'

describe GetCaseClassFromParamsService do
  let(:foi) { find_or_create :foi_correspondence_type }
  let(:ico) { find_or_create :ico_correspondence_type }
  let(:sar) { find_or_create :sar_correspondence_type }

  context 'FOIs' do
    it 'succeeds with Case::FOI::Standard' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: foi,
        params: { type: 'Standard' }
      )

      get_case_class_service.call
      expect(get_case_class_service.case_class).to eq Case::FOI::Standard
    end

    it 'succeeds with Case::FOI::TimelinessReview' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: foi,
        params: { type: 'TimelinessReview' }
      )

      get_case_class_service.call
      expect(get_case_class_service.error?).to be_falsey
      expect(get_case_class_service.case_class).to eq Case::FOI::TimelinessReview
    end

    it 'succeeds with Case::FOI::ComplianceReview' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: foi,
        params: { type: 'ComplianceReview' }
      )

      get_case_class_service.call
      expect(get_case_class_service.error?).to be_falsey
      expect(get_case_class_service.case_class).to eq Case::FOI::ComplianceReview
    end

    it 'gets error with non-existant FOI types' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: foi,
        params: { type: 'Unknown' }
      )

      get_case_class_service.call
      expect(get_case_class_service.error?).to be_truthy
      expect(get_case_class_service.case_class).to eq Case::FOI::Standard
    end
  end

  context 'SARs' do
    it 'succeeds with Case::SAR' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: sar,
        params: { type: nil }
      )

      get_case_class_service.call
      expect(get_case_class_service.case_class).to eq Case::SAR
    end
  end

  context 'ICOs' do
    let(:foi_case) { create(:foi_case) }
    let(:sar_case) { create(:sar_case) }

    it 'succeeds with Case::ICO::FOI' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: ico,
        params: { original_case_id: foi_case.id.to_s }
      )

      get_case_class_service.call
      expect(get_case_class_service.case_class).to eq Case::ICO::FOI
    end

    it 'succeeds with Case::ICO::SAR' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: ico,
        params: { original_case_id: sar_case.id.to_s }
      )

      get_case_class_service.call
      expect(get_case_class_service.case_class).to eq Case::ICO::SAR
    end

    it 'gets error with non-existant ICO types' do
      get_case_class_service = GetCaseClassFromParamsService.new(
        type: ico,
        params: { original_case_id: 'invalid' }
      )

      expect {
        get_case_class_service.call
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
