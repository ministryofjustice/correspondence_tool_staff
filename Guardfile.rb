guard 'livereload' do
  watch(%r{app/views/.+\.(erb|haml|slim)})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(scss|js|html|haml))).*}) { |m| "/assets/#{m[3]}" }
end

#guard :jasmine do
 # watch(%r{^spec/javascripts/.*(?:_s|S)pec\.(coffee|js)$})
  #watch(%r{app/assets/javascripts/(.+?)\.(js\.coffee|js|coffee)(?:\.\w+)*$}) do |m|
   # "spec/javascripts/jasmine/#{ m[1] }_spec.#{ m[2] }"
  #end
#end

guard :rspec, cmd: "bundle exec rspec -fd" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/interfaces/api/(.+)\.rb$}) { |m| "spec/api/#{m[1]}_spec.rb" }
end
