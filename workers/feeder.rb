class Feeder
  include Sidekiq::Worker
  sidekiq_options :queue => :feeder
  REDIS_POOL = ConnectionPool.new(:size => 25, :timeout => 5) { Redis.new }

  def perform(feed_url, interval = 300, last_update = 0)
    REDIS_POOL.with do |r|
      begin
        open(feed_url) do |rss|
          feed = RSS::Parser.parse rss
          puts "parsed #{feed.items.count} items"
          items = feed.items
          if feed.instance_of? RSS::Atom::Feed
            item_urls = items.select { |i| !i.date || i.date.to_f > last_update }
                             .map    { |i| i.link.href }
          else
            item_urls = items.select { |i| !i.date || i.date.to_f > last_update }
                             .map(&:link)
          end

          hashed_urls = hash_urls item_urls
          parsed, failed = r.smembers('items:parsed'), r.smembers('items:failed') 
          to_prune = parsed.concat failed

          hashed_urls.select { |(hash, _  )| !to_prune.include? hash }
                     .each   { |(hash, url)| Scraper.perform_async url, hash }

          self.class.perform_in(
                          next_interval(feed,interval,last_update), 
                          feed_url, 
                          Time.now.to_f
                          )
        end
      rescue => e
        r.hset 'feeds:failed:exceptions', feed_url, e.message 
        r.sadd 'feeds:failed', feed_url
        puts "feed failed: #{feed_url}"
      end
    end
  end

  def hash_urls urls
    urls.inject({}) do |hash, url|
      hash[Digest::SHA1.hexdigest url] = url
      hash
    end
  end

  def next_interval(*args) 
    # TODO: something more intelligent
    return 300
  end

end