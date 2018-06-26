$stdout.sync = true

require 'slack-ruby-client'
require 'json'
require 'httparty'
require 'redis'

SLACK_BOT_TOKEN = ENV["SLACK_BOT_TOKEN"].freeze

REDIS_URL = ENV["REDIS_URL"].freeze
REDIS_KEY = "PERSONAL_REDIS_KEY".freeze

class RedisHash
  def initialize
    puts "Initializing Redis Client"
    raise "ENV value REDIS_URL is not set" unless REDIS_URL.present?
    @redis = Redis.new(url: REDIS_URL)

    puts "Initializing Environment Map"
    @hash = JSON.parse(@redis.get(REDIS_KEY))
    @hash ||= Hash.new { |h, key| h[key] = nil }
    ENVIRONMENTS.each do |env|
      @hash[env] = nil unless @hash[env].present?
    end
    @hash = Hash[@hash.sort]

    puts "Creating Lock"
    @lock = Mutex.new
  end

  def [](key)
    @hash[key]
  end

  def []=(key, val)
    @lock.synchronize {
      @hash[key] = user
    }
  end

  def save
    @lock.synchronize {
      @redis.set REDIS_KEY, @hash.to_json
    }
  end

  def each(&block)
    @hash.each(&block)
  end
end

$state = RedisHash.new
$lock = Mutex.new

# start! throws on flaky internet; attempt to auto-reconnect
def start_with_retry!
  loop do
    begin
      $cl.start!
      break
    rescue StandardError
      sleep 1
      puts "Retrying at #{Time.now}"
    end
  end
end

def message(data, message)
  $cl.message channel: data.channel, text: message
end


def process(data)
  tokens = data.text.split(' ')
  puts "tokens: #{tokens}"
end

puts "Initializing Slack Client"
raise "ENV value SLACK_BOT_TOKEN is not set" unless SLACK_BOT_TOKEN.present?
$cl = Slack::RealTime::Client.new(token: SLACK_BOT_TOKEN)
$web = Slack::Web::Client.new(token: SLACK_BOT_TOKEN)

# Initial connection
$cl.on :hello do
  puts 'Running'
  $botid = $cl.self.id
  $botname = $cl.self.name

end

$cl.on :message do |data|
  # Do work
  process(data)
end

# Slack doesn't just call this when the bot is control-C'd
# It gets called whenever the Slack connection is broken (flaky internet, behind-the-scenes load balancing, etc.)
$cl.on :close do
  puts 'Closing'
end

# ...so you want to auto-restart the bot here, otherwise it will stay down
$cl.on :closed do
  puts 'Closed'
  start_with_retry!
end

start_with_retry!
