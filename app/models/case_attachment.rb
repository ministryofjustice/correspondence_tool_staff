# == Schema Information
#
# Table name: case_attachments
#
#  id           :integer          not null, primary key
#  case_id      :integer
#  type         :enum
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  key          :string
#  preview_key  :string
#  upload_group :string
#  user_id      :integer
#

class CaseAttachment < ApplicationRecord
  UNCONVERTIBLE_EXTENSIONS = %w[.pdf .jpg .jpeg .bmp .gif .png].freeze

  self.inheritance_column = :_type_not_used
  belongs_to :case,
             class_name: "Case::Base",
             inverse_of: :attachments

  validates :type, presence: true
  validates :key, presence: true
  validate :validate_file_extension, unless: proc { |a| a.key.nil? }

  after_destroy :remove_from_storage_bucket

  scope :ico_decisions, -> { where(type: :ico_decision) }

  enum :type, {
    response: "response",
    request: "request",
    ico_decision: "ico_decision",
    commissioning_document: "commissioning_document"
  }

  def filename
    File.basename(key)
  end

  def s3_object
    CASE_UPLOADS_S3_BUCKET.object(key)
  end

  def s3_preview_object
    preview_key.nil? ? nil : CASE_UPLOADS_S3_BUCKET.object(preview_key)
  end

  def temporary_url
    make_temporary_url_for(key)
  end

  def temporary_preview_url
    preview_key.nil? ? nil : make_temporary_url_for(preview_key)
  end

  def make_preview(retry_count)
    if not_convertible_file_type?
      self.preview_key = key
    else
      original_filepath = download_original_file
      preview_filepath = make_preview_filename
      begin
        Libreconv.convert original_filepath, preview_filepath
        self.preview_key = upload_preview(preview_filepath, retry_count)
      rescue StandardError => e
        Rails.logger.error "Error converting CaseAttachment #{id} to PDF"
        Rails.logger.error "#{e.class} - #{e.message}"
        Rails.logger.error e.backtrace
        self.preview_key = nil
      end
    end
    save!
  end

  def to_string
    s3_object.get.body.read
  end

private

  def not_convertible_file_type?
    File.extname(key).downcase.in? UNCONVERTIBLE_EXTENSIONS
  end

  def make_temporary_url_for(key)
    CASE_UPLOADS_S3_BUCKET.object(key).presigned_url :get, expires_in: Settings.attachments_presigned_url_expiry
  end

  def download_original_file
    extname = File.extname(key)
    original_file_tmpfile = Tempfile.new(["orig", extname])
    original_file_tmpfile.close
    attachment_object = CASE_UPLOADS_S3_BUCKET.object(key)
    attachment_object.get(response_target: original_file_tmpfile.path)
    original_file_tmpfile.path
  end

  def make_preview_filename
    preview_file = Tempfile.new(["preview", ".pdf"])
    preview_file.close
    preview_file.path
  end

  def upload_preview(filepath, retry_count)
    pdf_key = "#{self.case.attachments_dir('response_previews', upload_group)}/#{File.basename(key, File.extname(key))}.pdf"
    preview_object = CASE_UPLOADS_S3_BUCKET.object(pdf_key)
    result = preview_object.upload_file(filepath)
    if result == false
      if retry_count == Settings.s3_upload_max_tries
        raise "Max upload retry exceeded for CaseAttachment #{id}"
      else
        PdfMakerJob.perform_with_delay(id, retry_count + 1)
        pdf_key = nil
      end
    end
    pdf_key
  end

  def remove_from_storage_bucket
    s3_object.delete
    if !preview_key.nil? && preview_key != key
      s3_preview_object.delete
    end
  end

  def validate_file_extension
    mime_type = Rack::Mime.mime_type(File.extname(filename))
    unless Settings.case_uploads_accepted_types.include? mime_type
      errors.add(:url, I18n.t(
                         "activerecord.errors.models.case_attachment.attributes.url.bad_file_type",
                         type: mime_type,
                         filename:,
                       ))
    end
  end
end
