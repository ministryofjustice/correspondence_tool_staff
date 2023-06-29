# Determine whether or not a feature is enabled in this environment.
#
# usage (for e.g. feature :sars):
#
#   FeatureSet.sars.enabled?
#   FeatureSet.sars.disable!
#   FeatureSet.sars.enable!
#
#

class FeatureSet
  include Singleton

  class EnabledFeature
    def initialize(config)
      @env_config = config
      @host_env = HostEnv.host_env
    end

    def enabled?
      @env_config[@host_env] || false
    end

    def disabled?
      !enabled?
    end

    def enable!
      @env_config[@host_env] = true
    end

    def disable!
      @env_config[@host_env] = false
    end
  end

  def initialize
    @config = Settings.enabled_features
  end

  # so that we can write FeatureSet.sars, etc.
  def self.method_missing(meth)
    efs = instance
    efs.send(meth)
  end

  def method_missing(meth)
    if meth.in?(@config.keys)
      EnabledFeature.new(@config.__send__(meth))
    else
      super
    end
  end

  def self.respond_to_missing?(meth, _include_private = false)
    efs = instance
    efs.respond_to?(meth)
  end

  def respond_to_missing?(meth, _include_private = false)
    meth.in?(@config.keys) ? true : super
  end
end
