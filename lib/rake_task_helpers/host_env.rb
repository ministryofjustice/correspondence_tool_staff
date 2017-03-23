class HostEnv

  def self.staging?
    ENV['ENV'] == 'staging'
  end

  def self.dev?
    ENV['ENV'] == 'dev'
  end

  def self.safe?
    Rails.env.development? || Rails.env.test? || HostEnv.staging? || HostEnv.dev?
  end

  def self.safe
    if self.safe?
      yield
    else
      raise RuntimeError, 'This task can not be run in a live production environment'
    end
  end

end