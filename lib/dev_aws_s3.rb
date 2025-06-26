class DevAwsS3
  class Bucket
    attr_accessor :name

    def initialize(name)
      @name = name
      @objects = {}
    end

    def delete(key)
      @objects.delete(key)
    end

    def object(key)
      @objects[key] = Object.new(key, self)
    end

    def objects(options = {})
      if options.key? :prefix
        @objects
          .select { |path, _obj| path.start_with? options[:prefix] }
          .values
      else
        @objects.values
      end
    end

    def presigned_post(options = {})
      S3DirectPost.new(self, options)
    end
  end

  class Object
    attr_accessor :key

    INTERNAL_DIR_WITHOUT_BUCKET = "public/uploads/".freeze
    INTERNAL_DIR = "public/uploads/#{Settings.case_uploads_s3_bucket}/".freeze
    EXTERNAL_DIR = "uploads/#{Settings.case_uploads_s3_bucket}/".freeze

    def initialize(key, bucket)
      @key = key
      @bucket = bucket
    end

    def move_to(path)
      directory = "#{INTERNAL_DIR_WITHOUT_BUCKET}#{Pathname.new(path).dirname}"
      FileUtils.mkdir_p directory
      File.rename(key, "#{INTERNAL_DIR_WITHOUT_BUCKET}#{path}")
    end

    def delete
      file_path = "#{INTERNAL_DIR}#{key}"
      File.delete(file_path) if File.exist?(file_path)
    end

    def upload_file(_)
      nil
    end

    def presigned_url(*)
      "http://localhost:3000/#{EXTERNAL_DIR}#{key}"
    end

    def get
      OpenStruct.new(
        body: OpenStruct.new(
          read: IO.read("#{INTERNAL_DIR}#{key}"),
        ),
      )
    end
  end

  class S3DirectPost
    attr_accessor :bucket, :key, :options

    def initialize(bucket, options = {})
      @bucket = bucket
      @key = options.fetch(:key)
      options.delete(:key)
      @options = options
    end

    def fields
      {
        key:,
      }.merge(options)
    end

    def url
      "http://localhost:3000/dev_s3_uploader"
    end
  end

  def initialize
    @buckets = {}
  end

  def bucket(name)
    @buckets[name] = Bucket.new(name)
  end
end
