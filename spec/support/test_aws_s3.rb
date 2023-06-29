class TestAWSS3
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

    def url
      "https://s3.com/#{name}"
    end
  end

  class Object
    attr_accessor :key

    def initialize(key, bucket)
      @key = key
      @bucket = bucket
      @events = []
    end

    def move_to(path)
      @events << { event: :move_to, args: { path: } }
      @bucket.object(path)
    end

    def delete
      @bucket.delete(@key)
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
      "#{bucket.url}/s3_uploader"
    end
  end

  def initialize
    @buckets = {}
  end

  def bucket(name)
    @buckets[name] = Bucket.new(name)
  end
end
