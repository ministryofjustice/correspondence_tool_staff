require 'rails_helper'

describe RetentionSchedulesUpdateService do
  let!(:not_set_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'not_set',
      date: Date.today - 4.months
    ) 
  }

  let!(:reviewable_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'review',
      date: Date.today - (4.months - 7.days)
    ) 
  }

  let!(:retain_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'retain',
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
      action_text: "Mark for destruction"
    )
  }

  let(:service_with_error) {
    RetentionSchedulesUpdateService.new(
      retention_schedules_params: selected_cases_params,
      action_text: "non existant status"
    )
  }

  describe '#call' do
    it 'call to service updates correct cases' do
      service.call

      not_set_timely_kase.reload
      reviewable_timely_kase.reload

      expect(not_set_timely_kase.retention_schedule.status).to eq 'erasable'
      expect(reviewable_timely_kase.retention_schedule.status).to eq 'erasable'
      expect(retain_timely_kase.retention_schedule.status).to eq 'retain'
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
    it 'can resolve STATUS_ACTIONS to correct values' do
      correct_statues = RetentionSchedule.statuses
      statuses = RetentionSchedulesUpdateService::STATUS_ACTIONS

      expect(statuses[:further_review_needed]).to eq correct_statues[:review]
      expect(statuses[:retain]).to eq correct_statues[:retain]
      expect(statuses[:mark_for_destruction]).to eq correct_statues[:erasable]
      expect(statuses[:destroy_cases]).to eq correct_statues[:erased]
    end
  end


  def case_with_retention_schedule(case_type:, status:, date:)
    kase = create(
      case_type, 
      retention_schedule: 
        RetentionSchedule.new( 
         status: status, 
         planned_erasure_date: date 
      ) 
    )
    kase.save
    kase
  end
end
