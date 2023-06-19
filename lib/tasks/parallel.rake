namespace :parallel do
  namespace :spec do
    desc "Run only the feature specs"
    task features: :environment do
      abort unless system("parallel_test --type rspec spec/features")
    end

    desc "Run only the [non-feature] specs"
    task non_features: :environment do
      abort unless system('parallel_test --type rspec `find spec -not -path "spec/features*" -name "*_spec.rb"`')
    end

    desc "Run only the [stats and model] specs"
    task stats: :environment do
      abort unless system('parallel_test --type rspec `find spec -path "spec/services/stats*" -or -path "spec/models/*" -name "*_spec.rb"`')
    end
  end
end
