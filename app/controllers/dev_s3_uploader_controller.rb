class DevS3UploaderController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    FileUtils.mkdir_p(directory)
    File.rename(file.path, path)

    render xml: { "Key": path }, status: :created
  end

private

  def directory
    params[:key].gsub("/${filename}", "")
  end

  def path
    "#{directory}/#{file.original_filename}"
  end

  def file
    params[:file]
  end
end
