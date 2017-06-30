def stub_s3_uploader_for_all_files!
  s3_object = instance_double(Aws::S3::Object, move_to: nil)
  allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).and_return(s3_object)
  s3_objects = instance_double(Aws::Resources::Collection, each: [])
  allow(CASE_UPLOADS_S3_BUCKET).to receive(:objects).with(any_args)
                                     .and_return(s3_objects)
end
