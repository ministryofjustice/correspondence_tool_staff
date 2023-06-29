# Lovingly lifted from https://github.com/rails/sprockets-rails/issues/49#issuecomment-20535134

namespace :assets do
  desc "Copy precompiled assets to a filename without the fingerprint, suitable for static file use"
  task non_digested: :environment do
    assets = Dir.glob(Rails.root.join("public/assets/**/*"))
    regex = /(-{1}[a-z0-9]{32}*\.{1}){1}/
    assets.each do |file|
      next if File.directory?(file) || file !~ regex

      source = file.split("/")
      source.push(source.pop.gsub(regex, "."))

      non_digested = File.join(source)
      FileUtils.cp(file, non_digested)
    end
  end
end
