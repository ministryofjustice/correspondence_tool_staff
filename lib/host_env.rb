class HostEnv

  def self.staging?
    ENV['ENV'] == 'staging'
  end

  def self.dev?
    ENV['ENV'] == 'dev'
  end

  def self.demo?
    ENV['ENV'] == 'demo'
  end

  def self.prod?
    ENV['ENV'] == 'prod'
  end

  def self.test?
    Rails.env.test?
    # ENV['ENV'] == 'test'
  end

  def self.local?
    host_env == 'Local'
  end

  def self.host_env
    if ENV['ENV'].nil? && ( Rails.env.development? || Rails.env.test? )
      'Local'
    else
      "Host-#{ENV['ENV']}"
    end
  end


  def self.safe?
    Rails.env.development? || Rails.env.test? || HostEnv.staging? || HostEnv.dev? || HostEnv.demo?
  end



  def self.safe
    if self.safe?
      yield
    else
      raise RuntimeError, 'This task can not be run in a live production environment'
    end
  end

end
