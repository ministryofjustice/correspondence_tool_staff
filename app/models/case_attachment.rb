# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CaseAttachment < ActiveRecord::Base
  self.inheritance_column = :_type_not_used
  belongs_to :case

  validates :type, presence: true
  validates :url, presence: true
  validate :validate_url_file_extension, unless: Proc.new { |a| a.url.nil? }
  validate :validate_url_is_valid_host,  unless: Proc.new { |a| a.url.nil? }

  after_destroy :remove_from_storage_bucket

  enum type: { response: 'response' }

  def filename
    URI.decode(File.basename(s3_key))
  end

  def s3_object
    CASE_UPLOADS_S3_BUCKET.object(s3_key)
  end

  def s3_key
    URI.parse(url).path[1..-1]
  end

  private

  def remove_from_storage_bucket
    s3_object.delete
  end

  def validate_url_file_extension
    filename = File.basename URI.parse(url).path
    mime_type = Rack::Mime.mime_type(File.extname filename)
    unless Settings.case_uploads_accepted_types.include? mime_type
      errors[:url] << I18n.t(
        'activerecord.errors.models.case_attachment.attributes.url.bad_file_type',
        type: mime_type,
        filename: filename
      )
    end
  end

  def validate_url_is_valid_host
    s3_bucket_url = URI.parse(CASE_UPLOADS_S3_BUCKET.url)
    file_url = URI.parse(url)
    unless file_url.scheme == s3_bucket_url.scheme &&
           file_url.host   == s3_bucket_url.host
      errors[:url] << I18n.t(
        'activerecord.errors.models.case_attachment.attributes.url.invalid_url',
        filename: filename
      )
    end
  end
end
