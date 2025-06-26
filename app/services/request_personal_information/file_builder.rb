class RequestPersonalInformation::FileBuilder
  attr_accessor :rpi, :targets

  def initialize(rpi, targets)
    @rpi = rpi
    @targets = targets
  end

  def build(data)
    @data = data
    targets.each do |target|
      zip_attachments
      zip_pdf(target)
      upload(target)
    end
  end

private

  def zip_attachments
    Zip::File.open(zip_filename, create: true) do |zip|
      @data.attachments.each do |attachment|
        zip.get_output_stream(attachment.filename) do |output_entry_stream|
          output_entry_stream.write(attachment.file_data)
        end
      end
    end
  end

  def zip_pdf(target)
    md = rpi.to_markdown(target)
    Prawn::Document.generate(pdf_filename) { markdown(md) }
    Zip::File.open(zip_filename) do |zip|
      zip.add(pdf_filename, pdf_filename)
    end
    File.delete(pdf_filename)
  end

  def upload(target)
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(@rpi.key(target))
    File.open(zip_filename) do |f|
      uploads_object.upload_file(f)
      File.delete(f)
    end
  end

  def pdf_filename
    "tmp/#{@rpi.submission_id}.pdf"
  end

  def zip_filename
    "tmp/#{@rpi.submission_id}.zip"
  end
end
