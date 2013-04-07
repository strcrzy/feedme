class Scraper
  include Sidekiq::Worker
  sidekiq_options :queue => :scraper
  REDIS_POOL = ConnectionPool.new(:size => 25, :timeout => 5) { Redis.new }
  def perform(url, hash)
    REDIS_POOL.with do |r|
      begin
        open(url) do |body|
            html = body.read
            title = "no title"
            if match = /<title>(.*)<\/title>/.match(html)
              title = match[1]
            else
              title = r.hget('title', hash)
            end
            output = [url, title, html.length]
            r.lpush 'output', output.to_json
            r.sadd  'items:parsed', hash 
        end
      rescue => e
        r.hset 'items:failed:exceptions', url, e.message 
        r.sadd 'items:failed', hash
        puts "item failed: #{url}"
      end
    end
  end

end
