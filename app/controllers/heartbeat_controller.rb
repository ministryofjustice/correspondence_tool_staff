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
        database: database_alive?
    }

    status = :bad_gateway unless checks.values.all?
    render status: status, json: {
        checks: checks
    }
  end

  private

  def database_alive?
    begin
      ActiveRecord::Base.connection.active?
    rescue PG::ConnectionBad
      false
    end
  end
end
