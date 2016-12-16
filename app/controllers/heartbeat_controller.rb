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

end
