module DumperUtils
  def self.shell_working(message = "working", &block)
    ShellSpinner message, &block
  end

  def self.download_compressed_file(compressed_file, name_space, chosen_pod)
    shell_working sprintf("Downloading dump file %s from host %s", compressed_file, @host) do
      result = system "kubectl cp #{name_space}/#{chosen_pod}:/usr/src/app/#{compressed_file}, ./#{compressed_file}"
      raise "Unable to execute cp command" unless result == true
    end
  end

  def self.remove_files_on_container(compressed_file, prefix_command: nil)
    shell_working "removing file #{compressed_file}" do
      result = system "#{prefix_command.present? ? "#{prefix_command} " : ''}rm /usr/src/app/#{compressed_file}"
      raise "Unable to execute rm command" unless result == true
    end
  end

  def self.compress_file(filename, prefix_command: nil)
    result = false
    ShellSpinner "compressing file #{filename}" do
      result = system "#{prefix_command.present? ? prefix_command.to_s : ''}gzip -3 -f #{filename}"
    end
    raise "Unable to execute gzip command" unless result == true

    "#{filename}.gz"
  end

  def self.decompress_file(filename)
    shell_working "decompressing file #{filename}" do
      system "gunzip -f #{filename}"
    end
  end

  def self.question_user(query)
    print query
    input = $stdin.gets.chomp
    if input.downcase.start_with?("n") || input.nil?
      puts "exiting"
      exit # rubocop:disable Rails/Exit
    end
  end
end
