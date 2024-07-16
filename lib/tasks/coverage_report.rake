def directory_loop(name)
  Dir.foreach(name) do |file_name|
    p file_name
    next if [".", ".."].include?(file_name)

    file = File.join(name, file_name)

    if File.directory?(file)
      directory_loop(file)
    else
      next if File.extname(file_name) != ".zip"

      p "Found zip"
      Zip::File.open(file) do |zip_file|
        zip_file.each do |f|
          fpath = File.join("coverage", "#{SecureRandom.hex}.json")
          zip_file.extract(f, fpath)
        end
      end
    end
  end
end

namespace :coverage do
  desc "Collates all result sets generated by the different test runners"
  task report: :environment do
    require "simplecov"

    Dir.mkdir("coverage") unless File.exist?("coverage")
    directory_loop("coveragezip")
    SimpleCov.collate Dir["coverage/*"]
  end
end
