require 'rails_helper'

describe CaseDecorator, type: :model do
  let(:assigned_case)  { create :assigned_case }
  let(:responded_case) { create :responded_case }
  let(:manager)        { create :manager, managing_teams: [managing_team] }
  let(:managing_team)  { create :team_dacu }
  let(:responder)      { create :responder }
  let(:coworker)       { create :responder,
                                responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }


  describe '#who_its_with' do
    context 'case has no responding team assigned' do
      let(:assigned_case) { (create :case).decorate }

      before(:each) do
        allow_any_instance_of(CaseDecorator)
          .to receive(:h).and_return(double("View", current_user: manager))
      end

      it 'returns the managing teams name' do
        expect(assigned_case.who_its_with).to eq assigned_case.managing_team.name
      end
    end

    context 'case has been assigned but not accepted yet' do
      let(:assigned_case) { create :assigned_case }

      it 'returns the responding teams name' do
        expect(assigned_case.who_its_with).to eq assigned_case.responding_team.name
      end
    end

    context 'case is accepted by responder' do
      context 'as a case manager' do
        it 'returns the responding teams name' do
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'as the responder' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator)
            .to receive(:h).and_return(double("View", current_user: responder))
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'as a coworker of the responder' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator)
            .to receive(:h).and_return(double("View", current_user: coworker))
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'as the responder in another team' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator)
            .to receive(:h)
                  .and_return(double("View", current_user: another_responder))
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end
    end

    context 'case is responded' do
      it 'returns the managing team name' do
        expect(responded_case.who_its_with).to eq managing_team.name
      end
    end
  end

  describe '#time_taken' do
    it 'returns the number of business days taken to respond to a case' do
      assigned_case = create(:closed_case).decorate
      expect(assigned_case.time_taken).to eq '18 working days'
    end

    it 'uses singular "day" for 1 day' do
      assigned_case = create(:closed_case, date_responded: 21.business_days.ago).decorate
      expect(assigned_case.time_taken).to eq '1 working day'
    end
  end

  describe '#timeliness' do
    it 'returns correct string for answered in time' do
      assigned_case = create(:closed_case).decorate
      expect(assigned_case.timeliness).to eq 'Answered in time'
    end

    it 'returns correct string for answered late' do
      assigned_case = create(:closed_case, :late).decorate
      expect(assigned_case.timeliness).to eq 'Answered late'
    end
  end
end
