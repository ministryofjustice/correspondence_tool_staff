module DumperUtils

  def shell_working message = 'working', &block
    ShellSpinner message do
      yield
    end
  end

  def download_compressed_file(compressed_file, name_space, chosen_pod)
    shell_working 'Downloading dump file %s from host %s' % [compressed_file, @host] do
      result  = system "kubectl cp #{name_space}/#{chosen_pod}:/usr/src/app/#{compressed_file}, ./#{compressed_file}"
    end
    raise 'Unable to execute cp command' unless result == true
  end

  def remove_files_on_container(compressed_file, prefix_command: nil)
    shell_working "removing file #{compressed_file}" do
      result  = system "#{prefix_command.present? prefix_command + " " : ""}rm /usr/src/app/#{compressed_file}"
    end
    raise 'Unable to execute rm command' unless result == true
  end

  def exit_with_error(message)
    puts message.red
    Rake::Task['db:dump:help'].invoke
    exit 2
  end

  def compress_file(filename, prefix_command: nil)
    shell_working "compressing file #{filename}" do
      result  = system "#{prefix_command.present? prefix_command + " " : ""}gzip -3 -f #{filename}"
    end
    raise 'Unable to execute gzip command' unless result == true
    "#{filename}.gz"
  end

end