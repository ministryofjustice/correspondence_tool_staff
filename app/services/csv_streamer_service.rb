require 'csv'

class CSVStreamerService
  attr_reader :response, :attachment_name

  def initialize(response, attachment_name)
    puts ">>>>>>>>>> CSVStreamer SErvice  #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    puts ">>>>>>>>>> attachment name #{attachment_name} #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    @response = response
    @attachment_name = attachment_name
  end

  def send(objects)
    puts ">>>>>>>>>> SEND #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    puts ">>>>>>>>>> #{objects.size} #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    puts ">>>>>>>>>> #{objects.class} #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    response.headers['Content-Type'] = 'text/csv'
    response.headers['X-Accel-Buffering'] = 'no' # Stop NGINX from buffering
    timestamp = Time.now.strftime('%Y-%m-%d-%H%M%S')
    response.headers['Content-Disposition'] =
      %{attachment; filename="#{attachment_name}-#{timestamp}.csv"}
    response.stream.write(CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS))
    objects.each do |object|
      response.stream.write(CSV.generate_line(object.to_csv))
    end
  ensure
    response.stream.close
  end
end
