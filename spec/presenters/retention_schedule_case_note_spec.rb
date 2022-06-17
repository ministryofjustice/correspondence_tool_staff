require 'spec_helper'

RSpec.describe RetentionScheduleCaseNote do
  subject { described_class }

  describe '.new' do
    it 'is a private method' do
      expect(subject.respond_to?(:new)).to eq(false)
    end
  end

  describe '.log!' do
    let(:kase) { instance_double(Case::Base, state_machine: sm_double) }
    let(:user) { instance_double(User) }
    let(:team) { 'Team XYZ' }

    let(:sm_double) { double('StateMachine') }
    let(:args) { { kase: kase, user: user, changes: changes } }

    before do
      allow(user).to receive(:case_team).and_return(team)
    end

    context 'when there are no changes' do
      let(:changes) { {} }

      it 'does not write anything to the case history' do
        expect(sm_double).not_to receive(:add_note_to_case!)
        subject.log!(args)
      end
    end

    context 'when there are changes only in the `state` attribute' do
      let(:changes) { { state: [:not_set, :review] } }

      it 'writes the change to the case history' do
        expect(
          sm_double
        ).to receive(:add_note_to_case!).with(
          acting_user: user, acting_team: team,
          message: 'Retention status changed from Not set to Review'
        )

        subject.log!(args)
      end
    end

    context 'when there are changes only in the `planned_destruction_date` attribute' do
      let(:changes) { { planned_destruction_date: [Date.new(2018,10,25), Date.new(2025,12,31)] } }

      it 'writes the change to the case history' do
        expect(
          sm_double
        ).to receive(:add_note_to_case!).with(
          acting_user: user, acting_team: team,
          message: 'Destruction date changed from 25-10-2018 to 31-12-2025'
        )

        subject.log!(args)
      end
    end

    context 'when there are changes in both attributes' do
      let(:changes) { { state: [:not_set, :review], planned_destruction_date: [Date.new(2018,10,25), Date.new(2025,12,31)] } }

      it 'writes the change to the case history' do
        expect(
          sm_double
        ).to receive(:add_note_to_case!).with(
          acting_user: user, acting_team: team,
          message: "Retention status changed from Not set to Review\nDestruction date changed from 25-10-2018 to 31-12-2025"
        )

        subject.log!(args)
      end
    end
  end
end
