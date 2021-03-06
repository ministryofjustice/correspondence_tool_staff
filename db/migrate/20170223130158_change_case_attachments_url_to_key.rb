class ChangeCaseAttachmentsUrlToKey < ActiveRecord::Migration[5.0]
  class CaseAttachment < ActiveRecord::Base
    self.inheritance_column = :_type_not_used
  end

  def up
    CaseAttachment.connection.transaction do
      add_column :case_attachments, :key, :string
      CaseAttachment.all.each do |attachment|
        attachment.update_attributes(
          key: URI.decode(URI.parse(attachment.url).path.sub(%r{^/}, ''))
        )
      end
      add_index :case_attachments, :key, unique: true
      remove_column :case_attachments, :url
    end
  end

  def down
    CaseAttachment.connection.transaction do
      add_column :case_attachments, :url, :string
      bucket = Aws::S3::Resource.new.bucket(Settings.case_uploads_s3_bucket)
      CaseAttachment.all.each do |attachment|
        attachment.update_attributes(
          url: bucket.object(attachment.key).public_url
        )
      end
      remove_index :case_attachments, :key
      remove_column :case_attachments, :key
    end
  end
end
