# require 'aws-sdk-s3'

# rubocop:disable Rails/HelperInstanceVariable
module S3BucketHelper
  class S3Bucket
    attr_accessor :bucket_name

    def initialize(bucket: Settings.case_uploads_s3_bucket)
      @bucket_name = bucket
    end

    def put_object(key, body, metadata: nil)
      client.put_object({
        bucket: @bucket_name,
        key:,
        acl: "private",
        body:,
        metadata:,
      })
    end

    def get_object(key, **args)
      client.get_object(
        { bucket: @bucket_name, key: },
        **args,
      )
    end

    def list(folder_prefix = nil)
      bucket.objects({ prefix: folder_prefix })
    end

    def bucket
      @bucket ||= Aws::S3::Bucket.new(@bucket_name, { client: })
    end

    def client
      @client ||= Aws::S3::Client.new
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
