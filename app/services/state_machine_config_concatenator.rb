class StateMachineConfigConcatenator

  def initialize
    @part_files = Dir[Rails.root.join('config/state_machine/configs/**/*.yml')].sort
    @output_file_name = Rails.root.join('config/state_machine/moj.yml')
  end

  def run
    if needs_refresh?
      refresh!
    end
  end

  private

  def refresh!
    File.open(@output_file_name, 'w') do |fp|
      @part_files.each do |f|
        fp.puts IO.read(f)
      end
    end
  end

  def needs_refresh?
    File.exist?(@output_file_name) && output_file_newest? ? false : true
  end


  def output_file_newest?
    most_recent_modified_date < File.mtime(@output_file_name)
  end

  def most_recent_modified_date
    last_modified_time  = 50.years.ago
    @part_files.each do |f|
      mtime = File.mtime(f)
      last_modified_time = mtime if mtime > last_modified_time
    end
    last_modified_time
  end


end
