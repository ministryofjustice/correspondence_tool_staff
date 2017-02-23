# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  key        :string
#

class CaseAttachment < ActiveRecord::Base
  self.inheritance_column = :_type_not_used
  belongs_to :case

  validates :type, presence: true
  validates :key, presence: true
  validate :validate_file_extension, unless: Proc.new { |a| a.key.nil? }

  after_destroy :remove_from_storage_bucket

  enum type: { response: 'response' }

  def filename
    File.basename(key)
  end

  def s3_object
    CASE_UPLOADS_S3_BUCKET.object(key)
  end

  def url
    CASE_UPLOADS_S3_BUCKET.object(key).public_url
  end

  private

  def remove_from_storage_bucket
    s3_object.delete
  end

  def validate_file_extension
    mime_type = Rack::Mime.mime_type(File.extname filename)
    unless Settings.case_uploads_accepted_types.include? mime_type
      errors[:url] << I18n.t(
        'activerecord.errors.models.case_attachment.attributes.url.bad_file_type',
        type: mime_type,
        filename: filename
      )
    end
  end
end
