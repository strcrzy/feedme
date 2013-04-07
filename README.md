feedme
======

feedme is a toy news scraper, written on top of sidekiq and redis.
right now it runs locally, and expects redis at localhost. please provide it.

to get things started, run `bundle install`, then `./feedme <jsonfile>` where jsonfile is a json encoded array of dicts that each represent a feed.
each dict should look like this:
````
{"source_name": "1389blog.com", "id": 8, "feed_url": "http://1389blog.com/feed/"}
````

feedme will spawn off worker processes, as well as a webserver on port 3000 so you can observe the swarm in action. 
output will be printed to stdout.
