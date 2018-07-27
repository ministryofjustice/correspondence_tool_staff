require 'rails_helper'

RSpec::Matchers.define :allow_link do |klass|
  match do
    expect(described_class.classes_can_be_linked_with_type?(
             type: @type,
             klass: klass,
             linked_klass: @linked_klass
           )).to be_truthy
  end

  chain :to_case do |linked_klass|
    @linked_klass = linked_klass
  end

  chain :as_type do |type|
    @type = type
  end
end

# def allow_link(validator)
#   allow_link_matcher(validator)
# end


describe CaseLinkTypeValidator do
  describe '.classes_can_be_linked_with_type?' do
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::Standard)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }

    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::TimelinessReview)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }

    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::FOI::ComplianceReview)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }

    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::FOI::Standard)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::FOI::ComplianceReview)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::FOI::TimelinessReview)
                  .as_type(:related) }
    it { should allow_link(Case::ICO::FOI)
                  .to_case(Case::ICO::FOI)
                  .as_type(:related) }

    it { should allow_link(Case::SAR)
                  .to_case(Case::SAR )
                  .as_type(:related) }
    it { should allow_link(Case::SAR)
                  .to_case(Case::ICO::SAR )
                  .as_type(:related) }
    it { should allow_link(Case::ICO::SAR)
                  .to_case(Case::SAR )
                  .as_type(:related) }
    it { should allow_link(Case::ICO::SAR)
                  .to_case(Case::ICO::SAR )
                  .as_type(:related) }
  end

  describe '#validate' do
    it 'adds an error if cases cannot be linked' do
      allow(described_class).to receive(:classes_can_be_linked_with_type?)
                                  .and_return(false)
      foi1 = create(:foi_case)
      foi2 = create(:foi_case)
      case_link = LinkedCase.new(case: foi1, linked_case: foi2, type: :related)
      validator = CaseLinkTypeValidator.new
      validator.validate(case_link)
      expect(case_link.errors[:linked_case])
        .to eq ["can't link a FOI case to a FOI as a related case"]
      expect(CaseLinkTypeValidator)
        .to have_received(:classes_can_be_linked_with_type?)
              .with(type: 'related',
                    klass: Case::FOI::Standard,
                    linked_klass: Case::FOI::Standard)
    end
  end
end
