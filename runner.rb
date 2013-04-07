require './common'
class Runner
  def initialize(filename)
    @log = Logger.new(STDOUT)
    @log.info "reading sources from #{filename}"
    @json_sources = JSON.parse File.open(filename).read
    @log.info "found #{@json_sources.count} sources"
  end

  def start
    @json_sources.each do |source|
      source["feed_url"].insert(0,'http://')  unless source["feed_url"]['http://']
      Feeder.perform_async source["feed_url"]
      @log.info "queued feeder for feed at #{source['feed_url']}"
    end
  end
end


if __FILE__ == $0
  if ARGV[0]
    runner = Runner.new(ARGV[0])
    runner.start
  end
  @sidekiq_thin = Process.spawn "thin start"
  Signal.trap("INT") { Process.kill "INT", @sidekiq_thin; Process.exit }
  Signal.trap("KILL") { Process.kill "KILL", @sidekiq_thin; Process.exit }
  
  redis do |r|
    while output = JSON.parse(r.blpop('output').last) 
      puts "#{output[0]} - #{output[1]} - #{output[2]}"
    end
  end
end
