require 'rails_helper'

describe CaseDecorator, type: :model do
  let(:unassigned_case) { create(:case).decorate }
  let(:assigned_case)   { create(:assigned_case).decorate }
  let(:responded_case)  { create(:responded_case).decorate }
  let(:closed_case)     { create(:closed_case).decorate }
  let(:manager)         { create :manager, managing_teams: [managing_team] }
  let(:managing_team)   { create :team_dacu }
  let(:responder)       { create :responder }
  let(:coworker)        { create :responder,
                                 responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }


  describe '#who_its_with' do
    context 'case has no responding team assigned' do
      it 'returns the managing teams name' do
        expect(unassigned_case.who_its_with)
          .to eq unassigned_case.managing_team.name
      end
    end

    context 'case has been assigned but not accepted yet' do
      it 'returns the responding teams name' do
        expect(assigned_case.who_its_with)
          .to eq assigned_case.responding_team.name
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
      expect(closed_case.time_taken).to eq '18 working days'
    end

    it 'uses singular "day" for 1 day' do
      closed_case_21_days_old =
        create(:closed_case, date_responded: 21.business_days.ago).decorate
      expect(closed_case_21_days_old.time_taken).to eq '1 working day'
    end
  end

  describe '#timeliness' do
    it 'returns correct string for answered in time' do
      expect(closed_case.timeliness).to eq 'Answered in time'
    end

    it 'returns correct string for answered late' do
      closed_late_case = create(:closed_case, :late).decorate
      expect(closed_late_case.timeliness).to eq 'Answered late'
    end
  end

  describe '#internal deadline' do
    context 'unflagged case' do
      it 'returns nil' do
        unflagged_case = create(:case).decorate
        expect(unflagged_case.internal_deadline).to be_nil
      end
    end

    context 'flagged case' do
      it 'returns the internal deadline' do
        Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
          flagged_case = create :case, :flagged
          expect(flagged_case.internal_deadline).to eq DateTime.new(2017, 5, 16)
        end
      end
    end
  end

  describe '#requester_name_and_type' do
    it 'returns name and requestor type' do
      kase = create(:case, name: 'Stepriponikas Bonstart', requester_type: 'member_of_the_public').decorate
      expect(kase.requester_name_and_type).to eq 'Stepriponikas Bonstart | Member of the public'
    end
  end
end
