require "sidekiq/api"

class HeartbeatController < ApplicationController
  skip_before_action :check_maintenance_mode

  respond_to :json

  def ping
    version_info = {
      build_date: Settings.build_date,
      git_commit: Settings.git_commit,
      build_tag: Settings.git_source,
    }

    render json: version_info
  end

  def healthcheck
    all_checks = {
      database: database_alive?,
      redis: redis_alive?,
      sidekiq: sidekiq_alive?,
      sidekiq_queue: sidekiq_queue_healthy?,
    }
    key_checks = {
      database: database_alive?,
      redis: redis_alive?,
      sidekiq: sidekiq_alive?,
    }

    status = :bad_gateway unless key_checks.values.all?
    render status:, json: {
      checks: all_checks,
    }
  end

private

  def redis_alive?
    Sidekiq.redis_info
    true
  rescue StandardError
    false
  end

  def sidekiq_alive?
    ps = Sidekiq::ProcessSet.new
    !ps.size.zero? # rubocop:disable Style/ZeroLengthPredicate
  rescue StandardError
    false
  end

  def sidekiq_queue_healthy?
    dead = Sidekiq::DeadSet.new
    retries = Sidekiq::RetrySet.new
    dead.size.zero? && retries.size.zero? # rubocop:disable Style/ZeroLengthPredicate
  rescue StandardError
    false
  end

  def database_alive?
    tuple = ActiveRecord::Base.connection.execute("select 1 as result")
    tuple.to_a == [{ "result" => 1 }]
  rescue StandardError
    false
  end
end
