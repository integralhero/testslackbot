require 'slack-ruby-client'
require 'logger'


logger = Logger.new(STDOUT)

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

client = Slack::RealTime::Client.new
client.on :message do |data|
	return if data.user == "chimebot"

	client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
end
client.start!
