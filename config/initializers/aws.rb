Aws.config.update region: 'eu-west-1',
                  credentials: Aws::Credentials.new(
                    Settings.aws_access_key_id,
                    Settings.aws_secret_access_key
                  )

CASE_UPLOADS_S3_BUCKET = Aws::S3::Resource.new.bucket(Settings.case_uploads_s3_bucket)
