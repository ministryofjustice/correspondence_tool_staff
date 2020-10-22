# require 'aws-sdk-s3'

module S3BucketHelper

  Credentials = Struct.new(:access_key_id, :secret_access_key, :bucket)

  class S3Bucket

    def initialize(access_key_id, secret_access_key)
      @credentials = Credentials.new(
        access_key_id,
        secret_access_key,
        Settings.case_uploads_s3_bucket
      )
    end

    attr_reader :host

    def put_object(key, body, metadata: nil)
      client.put_object({
        bucket: credentials.bucket,
        key: key,
        acl: 'private',
        body: body,
        metadata: metadata
      })
    end

    def get_object(key, **args)
      client.get_object(
        {bucket: credentials.bucket, key: key},
        **args
      )
    end

    def list(folder_prefix = nil)
      bucket.objects({prefix: folder_prefix})
    end

    def bucket
      @bucket ||= Aws::S3::Bucket.new(credentials.bucket, { client: client })
    end

    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: credentials.access_key_id,
        secret_access_key: credentials.secret_access_key
      )
    end

  end
end