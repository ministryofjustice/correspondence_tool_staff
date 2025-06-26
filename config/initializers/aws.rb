# London
Aws.config.update region: "eu-west-2" # rubocop:disable Rails/SaveBang

CASE_UPLOADS_S3_BUCKET = if Rails.env.development?
                           require_relative "../../lib/dev_aws_s3"
                           DevAwsS3::Bucket.new(Settings.case_uploads_s3_bucket)
                         else
                           Aws::S3::Resource.new.bucket(Settings.case_uploads_s3_bucket)
                         end
