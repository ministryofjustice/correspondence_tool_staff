class RpiController < ApplicationController
  def show
    submission_id = params[:id]
    tmpfile_path = download_to_tmpfile("rpi/#{submission_id}")
    send_file tmpfile_path, type: Rack::Mime.mime_type("zip"), disposition: "inline"
  end

private

  def download_to_tmpfile(key)
    extname = File.extname(key)
    tmpfile = Tempfile.new(["orig", extname])
    tmpfile.close
    attachment_object = CASE_UPLOADS_S3_BUCKET.object(key)
    attachment_object.get(response_target: tmpfile.path)
    tmpfile.path
  end
end
