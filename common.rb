require 'json'
require 'sidekiq'
require 'open-uri'
require 'rss'
require 'logger'
require './workers/feeder'
require './workers/scraper'

def redis &block
  Sidekiq.redis(&block)
end