sysctl_ncpu = `sysctl -n hw.ncpu`.to_i
ncpu = sysctl_ncpu <= 1 ? sysctl_ncpu : sysctl_ncpu - 1

rspec_options = {
  cmd: "bundle exec rspec",
  run_all: {
    cmd: "bundle exec parallel_rspec -n #{ncpu} -o '",
    cmd_additional_args: "'",
  },
  failed_mode: :focus,
}

guard "livereload" do
  watch(%r{app/views/.+\.(erb|haml|slim)})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(scss|js|html|haml))).*}) { |m| "/assets/#{m[3]}" }
end

# guard :jasmine do
# watch(%r{^spec/javascripts/.*(?:_s|S)pec\.(coffee|js)$})
# watch(%r{app/assets/javascripts/(.+?)\.(js\.coffee|js|coffee)(?:\.\w+)*$}) do |m|
# "spec/javascripts/jasmine/#{ m[1] }_spec.#{ m[2] }"
# end
# end

guard :rspec, rspec_options do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_controller\.rb}) do |m|
    ["spec/controllers/#{m[1]}_controller_spec.rb",
     "spec/controllers/#{m[1]}/*_spec.rb"]
  end
  watch(%r{^app/interfaces/api/(.+)\.rb$}) { |m| "spec/api/#{m[1]}_spec.rb" }
end

guard :rubocop, all_on_start: false, cli: ["--format", "clang", "--rails"] do
  watch(%r{.*\.rb$})
end

guard :brakeman, run_on_start: true, quiet: true do
  watch(%r{^app/.+\.(erb|haml|rhtml|rb|slim|js)$})
  watch(%r{^config/.+\.rb$})
  watch(%r{^lib/.+\.rb$})
  watch("Gemfile")
end

guard :jasmine do
  watch(%r{spec/javascripts/spec\.(js\.coffee|js|coffee)$}) { "spec/javascripts" }
  watch(%r{spec/javascripts/modules/.*(?:_s|S)\.(js\.coffee|js|coffee)$})
  watch(%r{spec/javascripts/.*(?:_s|S)\.(js\.coffee|js|coffee)$})

  watch(%r{spec/javascripts/fixtures/.+$})
  watch(%r{app/assets/javascripts/(.+?)\.(js\.coffee|js|coffee)(?:\.\w+)*$}) do |m|
    "spec/javascripts/jasmine/#{m[1]}_spec.#{m[2]}"
  end
end
