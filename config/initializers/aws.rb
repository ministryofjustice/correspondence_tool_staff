# London
Aws.config.update region: "eu-west-2" # rubocop:disable Rails/SaveBang

CASE_UPLOADS_S3_BUCKET = Aws::S3::Resource.new.bucket(Settings.case_uploads_s3_bucket)
