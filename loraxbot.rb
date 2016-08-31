require 'slack-ruby-client'
require "httparty"
CHIMEBOT_ID = "U25FSAV6Y"
DEBUG_MODE = true

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

def get_user_session(id)
	date = Time.now.strftime("%m%d%Y%H%M%S")
	return "#{id.to_s}#{date}"
end

nums = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
web_client = Slack::Web::Client.new
client = Slack::RealTime::Client.new
sessions = {}
actions = {}




client.on :reaction_added do |data|

	puts "Reaction is added: #{data.inspect}"
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])

		message_ts = data['item']['ts']
		message_channel = data['item']['channel']
		reaction_name = data['reaction']
		puts "SESSIONS: #{sessions.inspect}"

		puts "#{data['user']} just added a #{reaction_name} to #{message_channel} at #{message_ts}"
		text = "#{sessions[data['user']][message_channel][message_ts][reaction_name]}"
		puts text
		client.message channel: data['item']['channel'], text: "User selected-> #{text}!" if DEBUG_MODE
	end
	
end

# General Message handler
# TODO: Currently generating unique session_id per call (per second). Not sure why, but I get low confidence back when I use an existing session and get no matches from Wit.ai
client.on :message do |data|
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])
		
		timenow = Time.now.strftime("%Y%m%d")
		api_key_wit = ENV['WIT_API_TOKEN']
		response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}"}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
		# client.message channel: data['channel'], text: "#{response.to_s}" if DEBUG_MODE
		puts "Response from WIT: #{response.inspect}"
		case response["type"]
		when "msg"
			puts "Got a message"
			client.typing channel: data['channel']
			client.message channel: data['channel'], text: "#{response["msg"]}"
		when "action"
			action_name = response["action"]
		when "merge"
			#execute merge actions
		else
			puts "None matched"
			client.message channel: data['channel'], text: "Hi <@#{data['user']}>! Your command was not recognized. Try testing me with some common queries"
		end
		if response.key?("quickreplies")
			# puts response["quickreplies"]
			index = 1
			emojis = []
			message = "Please select one of the following options for further inquiries: \n"
			for reply in response["quickreplies"] do
				num_as_emoji = ":#{nums[index]}:"
				option_str = "#{num_as_emoji} #{reply} \n"
				message += option_str
				emojis.push("#{nums[index]}")
				index += 1
			end
			chatbot_response = web_client.chat_postMessage channel: data['channel'], text: "#{message}", as_user: true
			puts "Chatbot response: #{chatbot_response.ts}"
			for i in 0...response["quickreplies"].size

				#HACK: session_id is set to user_id, but this should not be the case once session storage/retrieval is figured out
				session_id = data['user']
				sessions[session_id] = {}

				reply_text = response["quickreplies"][i]
				puts "add emoji: #{emojis[i]} on #{chatbot_response.channel} at #{chatbot_response.ts}"
				web_client.reactions_add(name: emojis[i], channel: chatbot_response.channel, timestamp: chatbot_response.ts)
				sessions[session_id][chatbot_response.channel] = {} if !sessions[session_id].key? chatbot_response.channel && i == 0
				sessions[session_id][chatbot_response.channel][chatbot_response.ts] = {} if i == 0
				sessions[session_id][chatbot_response.channel][chatbot_response.ts][emojis[i]] = reply_text
				puts "SESSION PRINT: #{sessions.inspect}"
			end
			
		end
		
	end
end
client.start!
