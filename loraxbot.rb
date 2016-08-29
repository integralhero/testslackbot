require 'slack-ruby-bot'

class LoraxBot < SlackRubyBot::Bot

  def generate_session_id(data)
  	user_id = data['user']['id']
  	return user_id + Time.now.strftime("%m/%d/%Y")
  end
  
  match '/(?<message>((\w* ?)*))/' do |client, data, match|
    client.say(text: "Hello there, you said #{match[:location]}!", channel: data.channel)
    logger.info generate_session_id(data)
  end
end

LoraxBot.run