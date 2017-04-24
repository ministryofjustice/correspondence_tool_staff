require 'rails_helper'

describe CaseDecorator, type: :model do

  let(:manager) { create :manager }
  let(:responder) { create :responder }
  let(:coworker)  { create :responder, responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }


  describe '#who_its_with' do
    context 'case has no responding team assigned' do

      before(:each) { allow_any_instance_of(CaseDecorator).to receive(:h).and_return(double("View", current_user: manager)) }
      let(:kase) { (create :case).decorate }

      it 'returns the managing teams name' do
        expect(kase.who_its_with).to eq kase.managing_team.name
      end
    end

    context 'case has been assigned but not accepted yet' do
      let(:kase) { create :assigned_case }

      it 'returns the responding teams name' do
        expect(kase.who_its_with).to eq kase.responding_team.name
      end
    end

    context 'case is accepted by responder' do
      let(:kase) { create :assigned_case }

      context 'as a case manager' do
        it 'returns the responding teams name' do
          expect(kase.who_its_with).to eq kase.responding_team.name
        end
      end

      context 'as the responder' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator).to receive(:h).and_return(double("View", current_user: responder))
          expect(kase.who_its_with).to eq kase.responding_team.name
        end
      end

      context 'as a coworker of the responder' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator).to receive(:h).and_return(double("View", current_user: coworker))
          expect(kase.who_its_with).to eq kase.responding_team.name
        end
      end

      context 'as the responder in another team' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator).to receive(:h).and_return(double("View", current_user: another_responder))
          expect(kase.who_its_with).to eq kase.responding_team.name
        end
      end
    end

  end

  describe '#time_taken' do
    it 'returns the number of business days taken to respond to a case' do
      kase = create(:closed_case).decorate
      expect(kase.time_taken).to eq '18 working days'
    end

    it 'uses singular "day" for 1 day' do
      kase = create(:closed_case, date_responded: 21.business_days.ago).decorate
      expect(kase.time_taken).to eq '1 working day'
    end
  end

  describe '#timeliness' do
    it 'returns correct string for answered in time' do
      kase = create(:closed_case).decorate
      expect(kase.timeliness).to eq 'Answered in time'
    end

    it 'returns correct string for answered late' do
      kase = create(:closed_case, :late).decorate
      expect(kase.timeliness).to eq 'Answered late'
    end
  end
end

