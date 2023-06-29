def disable_feature(feature_name)
  feature = instance_double(FeatureSet::EnabledFeature,
                            enabled?: false,
                            disabled?: true)
  allow(FeatureSet).to receive(feature_name).and_return(feature)
end

def enable_feature(feature_name)
  feature = instance_double(FeatureSet::EnabledFeature,
                            enabled?: true,
                            disabled?: false)
  allow(FeatureSet).to receive(feature_name).and_return(feature)
end
