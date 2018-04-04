def stub_s3_uploader_for_all_files!
  s3_objects = Hash.new do |hash, key|
    hash[key] = instance_double(Aws::S3::Object,
                                delete: nil,
                                get: nil,
                                key: key,
                                move_to: nil,
                                upload_file: nil)
  end
  allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with(any_args) do |key|
    s3_objects[key]
  end

  s3_object_collections = Hash.new do |hash, prefix|
    hash[prefix] = instance_double(Aws::Resources::Collection, each: [])
  end

  allow(CASE_UPLOADS_S3_BUCKET).to receive(:objects).with(any_args) do |args|
    s3_object_collections[args[:prefix]]
  end
end
