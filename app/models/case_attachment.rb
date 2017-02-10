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

  enum type: { response: 'response' }

  def filename
    URI.decode(
      File.basename(
        URI.parse(url).path
      )
    )
  end

  private

  def validate_url_file_extension
    filename = File.basename URI.parse(url).path
    mime_type = Rack::Mime.mime_type(File.extname filename)
    unless Settings.case_uploads_accepted_types.include? mime_type
      errors[:url] << I18n.t(
        'activerecord.errors.models.case_attachment.attributes.url.bad_file_type',
        type: mime_type,
        name: File.basename(URI.parse(url).path)
      )
    end
  end
end
