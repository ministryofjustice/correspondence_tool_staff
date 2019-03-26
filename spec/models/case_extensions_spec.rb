require  'rails_helper'

describe 'Spec Support Extensions for Case Model' do

  describe '#assigned_disclosure_specialist!' do
    context 'when there is an assigned disclosure specialist' do
      it 'returns the user record' do
        kase = create :pending_dacu_clearance_case
        sd = kase.assigned_disclosure_specialist!
        expect(sd).to be_instance_of(User)
        expect(sd.teams).to include BusinessUnit.dacu_disclosure
      end
    end

    context 'when there is no assigned disclosure specialist' do
      it 'raises' do
        kase = create :case
        expect {
          kase.assigned_disclosure_specialist!
        }.to raise_error RuntimeError, 'No assigned disclosure specialist'
      end
    end
  end


  describe '#assigned_press_officer!' do
    context 'when there is a press officer' do
      it 'returns the user record' do
        kase = create :pending_press_clearance_case
        sd = kase.assigned_press_officer!
        expect(sd).to be_instance_of(User)
        expect(sd.teams).to include BusinessUnit.press_office
      end
    end

    context 'when there is no assigned disclosure specialist' do
      it 'raises' do
        kase = create :case
        expect {
          kase.assigned_press_officer!
        }.to raise_error RuntimeError, 'No assigned press officer'
      end
    end
  end

  describe '#assigned_private_officer!' do
    context 'when there is a private officer' do
      it 'returns the user record' do
        kase = create :pending_private_clearance_case
        sd = kase.assigned_private_officer!
        expect(sd).to be_instance_of(User)
        expect(sd.teams).to include BusinessUnit.private_office
      end
    end

    context 'when there is no assigned disclosure specialist' do
      it 'raises' do
        kase = create :case
        expect {
          kase.assigned_private_officer!
        }.to raise_error RuntimeError, 'No assigned private officer'
      end
    end
  end

end
