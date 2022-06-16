require 'rails_helper'

describe RetentionSchedulesUpdateService do
  let(:manager)         { find_or_create :branston_user }
  let(:managing_team)   { create :managing_team, managers: [manager] }

  let!(:not_set_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      state: 'not_set',
      date: Date.today - 4.months
    ) 
  }

  let!(:reviewable_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      state: 'review',
      date: Date.today - (4.months - 7.days)
    ) 
  }

  let!(:retain_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      state: 'retain',
      date: Date.today - (4.months - 7.days)
    ) 
  }

  let(:selected_cases_params) do
    ActiveSupport::HashWithIndifferentAccess.new(
      {
        not_set_timely_kase.id => '1',
        reviewable_timely_kase.id => '1',
        retain_timely_kase.id => '0'
      }
    )
  end

  let(:service) {
    RetentionSchedulesUpdateService.new(
      retention_schedules_params: selected_cases_params,
      event_text: "Mark for destruction",
      current_user: manager
    )
  }

  let(:service_with_error) {
    RetentionSchedulesUpdateService.new(
      retention_schedules_params: selected_cases_params,
      event_text: "non existant status",
      current_user: manager
    )
  }

  describe '#call' do
    before do
      service.call

      not_set_timely_kase.reload
      reviewable_timely_kase.reload
    end

    it 'call to service updates correct cases' do
      expect(not_set_timely_kase.retention_schedule.state).to eq 'to_be_anonymised'
      expect(reviewable_timely_kase.retention_schedule.state).to eq 'to_be_anonymised'
      expect(retain_timely_kase.retention_schedule.state).to eq 'retain'
    end

    it 'adds note to case history on state change' do
      history_message = reviewable_timely_kase
                          .transitions
                          .case_history
                          .last
                          .message

      expected_message = "Retention status changed from Review to Destroy"
      expect(history_message).to eq(expected_message)
    end
  end

  describe '#prepare_case_ids' do
    it 'returns case ids that have been selected' do
      ids = [
        not_set_timely_kase.id,
        reviewable_timely_kase.id,
      ]

      expect(service.prepare_case_ids).to eq ids
    end
  end

  describe 'exception handling' do
    it 'raises error if incorrect status action is passed' do
      service_with_error.call 
      error_message = 'Requested retention schedule status action is incorrect'
      expect(service_with_error.error_message).to eq(error_message)
      expect(service_with_error.result).to eq(:error)
    end
  end

  describe '#parameterize_status_action' do
    it 'can parameterize an action text' do
      expect(service.parameterize_status_action).to eq :mark_for_destruction
    end
  end

  describe 'constants' do
    it 'can resolve STATUS_ACTIONS to correct AASM event trigger method names' do
      statuses = RetentionSchedulesUpdateService::STATUS_ACTIONS

      expect(statuses[:further_review_needed]).to eq :mark_for_review
      expect(statuses[:retain]).to eq :mark_for_retention
      expect(statuses[:mark_for_destruction]).to eq :mark_for_anonymisation
      expect(statuses[:destroy_cases]).to eq :anonymise!
    end
  end

  def case_with_retention_schedule(case_type:, state:, date:)
    kase = create(
      case_type, 
      retention_schedule: 
        RetentionSchedule.new( 
         state: state,
         planned_destruction_date: date 
      ) 
    )
    kase.save
    kase
  end
end
