require 'slack-ruby-bot'
require 'logger'

logger = Logger.new(STDOUT)

class LoraxBot < SlackRubyBot::Bot

  def generate_session_id(data)
  	user_id = data['user']['id']
  	return user_id + Time.now.strftime("%m/%d/%Y")
  end
  
  match '/^(?<message>.*)$/' do |client, data, match|
    client.say(text: "Hello there, you said #{match[:message]}!", channel: data.channel)
    logger.info " Generated session_id: #{generate_session_id(data)}"
  end

  match /^How is the weather in (?<location>\w*)\?$/ do |client, data, match|
    client.say(channel: data.channel, text: "The weather in #{match[:location]} is nice.")
    logger.info " Generated session_id: #{generate_session_id(data)}"
  end
end

LoraxBot.run