require 'slack-ruby-client'
require 'logger'

CHIMEBOT_ID = "U25FSAV6Y"

logger = Logger.new(STDOUT)

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

client = Slack::RealTime::Client.new
client.on :message do |data|
	return if data['user'] == CHIMEBOT_ID

	client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
end
client.start!
