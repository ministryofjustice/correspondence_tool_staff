class RequestPersonalInformation::FileBuilder
  attr_accessor :rpi

  def initialize(rpi)
    @rpi = rpi
  end

  def build(data)
    @data = data
    zip_attachments
    zip_pdf
    upload
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

  def zip_pdf
    md = rpi.to_markdown
    Prawn::Document.generate(pdf_filename) { markdown(md) }
    Zip::File.open(zip_filename) do |zip|
      zip.add(pdf_filename, pdf_filename)
    end
    File.delete(pdf_filename)
  end

  def upload
    uploads_object = CASE_UPLOADS_S3_BUCKET.object("rpi/#{@data.submission_id}")
    File.open(zip_filename) do |f|
      uploads_object.upload_file(f)
      File.delete(f)
    end
  end

  def pdf_filename
    "#{@data.submission_id}.pdf"
  end

  def zip_filename
    "#{@data.submission_id}.zip"
  end
end
