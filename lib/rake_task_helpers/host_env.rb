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
