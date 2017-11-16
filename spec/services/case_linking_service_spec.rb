require "rails_helper"

describe CaseLinkingService do
  let(:manager)  { find_or_create :disclosure_bmt_user }
  let(:kase)     { create :case }
  let(:link_case){ create :case }
  let(:service)  { CaseLinkingService.new(manager,
                                          kase,
                                          link_case.number)}

  describe '#initialize' do
    it 'uses the provided user' do
      urs = CaseLinkingService.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@user)).to eq manager
    end

    it 'uses the provided kase' do
      urs = CaseLinkingService.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@case)).to eq kase
    end

    it 'uses the provided link_case_number' do
      urs = CaseLinkingService.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@link_case_number))
          .to eq link_case.number
    end

    it 'initialises a empty link_case instance var' do
      urs = CaseLinkingService.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@link_case)).to eq nil
    end

    it 'user result and defaults to incomplete' do
      urs = CaseLinkingService.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@result)).to eq :incomplete
    end

  end

  describe '#call' do

    before(:each)  { service.call }

    it 'creates a link to the linked case' do
      expect(kase.linked_cases).to eq [link_case]
    end

    it 'creates a link from the linked case to the linking case' do
      expect(link_case.linked_cases).to eq [kase]
    end

    it 'sets result to :ok and returns same' do
      result = service.call
      expect(result).to eq :ok
      expect(service.result).to eq :ok
    end

    it 'has created a transition on the linking case' do
      transition = kase.transitions.last
      expect(transition.event).to eq 'link_a_case'
      expect(transition.to_state).to eq kase.current_state
      expect(transition.linked_case_id).to eq link_case.id
      expect(transition.acting_user_id).to eq manager.id
      expect(transition.acting_team_id).to eq manager.teams.first.id
    end

    it 'has created a transition on the linked case' do
      transition = link_case.transitions.last
      expect(transition.event).to eq 'link_a_case'
      expect(transition.to_state).to eq link_case.current_state
      expect(transition.linked_case_id).to eq kase.id
      expect(transition.acting_user_id).to eq manager.id
      expect(transition.acting_team_id).to eq manager.teams.first.id
    end
  end

  context 'validations' do
    describe 'trying to link without a case number' do
      let(:service)  { CaseLinkingService.new(manager,
                                        kase,
                                        nil)}

      it 'sets result to validation error and returns same' do
        result = service.call
        expect(result).to eq :validation_error
        expect(service.result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(kase.errors[:linked_case_number])
          .to eq ["can't be blank"]
      end
    end

    describe 'trying to link to the same case' do
      let(:service)  { CaseLinkingService.new(manager,
                                        kase,
                                        kase.number)}

      it 'sets result to :validation error and returns same' do
        result = service.call
        expect(result).to eq :validation_error
        expect(service.result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(kase.errors[:linked_case_number])
          .to eq ["can't link to the same case"]
      end
    end

    describe 'trying to link a case that does not exist' do
      let(:service)  { CaseLinkingService.new(manager,
                                        kase,
                                        11111)}

      it 'sets result to validation error and returns same' do
        result = service.call
        expect(result).to eq :validation_error
        expect(service.result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(kase.errors[:linked_case_number])
          .to eq ["does not exist"]
      end
    end
  end

  context 'when an error occurs' do
    it 'rolls back changes' do
      allow(kase).to receive(:add_linked_case).and_throw(RuntimeError)
      service.call

      cases_transitions = kase.transitions.where(
        event: 'link_a_case'
      )
      expect(cases_transitions.any?).to be false

      link_cases_transitions = link_case.transitions.where(
        event: 'link_a_case'
      )
      expect(link_cases_transitions.any?).to be false
    end

    it 'sets result to :error and returns same' do
      allow(kase).to receive(:add_linked_case).and_throw(RuntimeError)
      result = service.call
      expect(result).to eq :error
      expect(service.result).to eq :error
    end
  end
end
