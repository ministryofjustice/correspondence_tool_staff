class HostEnv
  def self.staging?
    ENV["ENV"] == "staging"
  end

  def self.development?
    ENV["ENV"] == "dev"
  end

  def self.production?
    ENV["ENV"] == "prod"
  end

  def self.test?
    Rails.env.test?
  end

  def self.qa?
    ENV["ENV"] == "qa"
  end

  def self.local?
    host_env == "Local"
  end

  def self.host_env
    if ENV["ENV"].nil? && (Rails.env.development? || Rails.env.test?)
      "Local"
    else
      "Host-#{ENV['ENV']}"
    end
  end

  def self.safe?
    Rails.env.development? || Rails.env.test? || HostEnv.staging? || HostEnv.development? || HostEnv.qa?
  end

  def self.safe
    if safe?
      yield
    else
      raise "This task can not be run in a live production environment"
    end
  end
end
