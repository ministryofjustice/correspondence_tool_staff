require 'sidekiq/api'

class HeartbeatController < ApplicationController

  respond_to :json

  def ping
    version_info = {
      build_date: Settings.build_date,
      git_commit: Settings.git_commit,
      git_source: Settings.git_source
    }

    render json: version_info
  end

  def healthcheck
    checks = {
      database:      database_alive?,
      redis:         redis_alive?,
      sidekiq:       sidekiq_alive?,
      sidekiq_queue: sidekiq_queue_healthy?,
    }

    status = :bad_gateway unless checks.values.all?
    render status: status, json: {
        checks: checks
    }
  end

  private

  def redis_alive?
    Sidekiq.redis_info
    true
  rescue
    false
  end

  def sidekiq_alive?
    ps = Sidekiq::ProcessSet.new
    !ps.size.zero?
  rescue
    false
  end

  def sidekiq_queue_healthy?
    dead = Sidekiq::DeadSet.new
    retries = Sidekiq::RetrySet.new
    dead.size.zero? && retries.size.zero?
  rescue
    false
  end

  def database_alive?
    ActiveRecord::Base.connection.active?
  rescue PG::ConnectionBad
    false
  end
end
