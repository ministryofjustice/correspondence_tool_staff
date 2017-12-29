namespace :parallel do
  namespace :spec do
    desc 'Run only the feature specs'
    task :features do
      abort unless system('parallel_test --type rspec spec/features')
    end

    desc 'Run only the [non-feature] specs'
    task :non_features do
      abort unless system('parallel_test --type rspec `find spec -not -path "spec/features*" -name "*_spec.rb"`')
    end
    task specs: :non_features
  end
end

