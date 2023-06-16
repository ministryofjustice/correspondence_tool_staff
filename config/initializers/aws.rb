Aws.config.update! region: "eu-west-2" # London

CASE_UPLOADS_S3_BUCKET = Aws::S3::Resource.new.bucket(Settings.case_uploads_s3_bucket)
