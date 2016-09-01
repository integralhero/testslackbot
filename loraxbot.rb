require 'slack-ruby-client'
require "httparty"



CHIMEBOT_ID = "U25FSAV6Y"
DEBUG_MODE = true

nums = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
sessions = {}
actions = {}


Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

web_client = Slack::Web::Client.new
client = Slack::RealTime::Client.new

# get_user_session
# PARAM: user_id from slack to generate session id for Wit
def get_user_session(user_id)
	date = Time.now.strftime("%m%d%Y%H%M%S")
	return "#{user_id.to_s}#{date}"
end

# clear_session_context_for_user
# PARAM: user_id from slack
# returns whether session reset was successful
def clear_session_context_for_user(user_id)
	if sessions.key? user_id 
		sessions[user_id] = {}
		return true
	else
		return false
	end
end


def wit_converse(session_id, q, context={})
	api_key_wit = ENV['WIT_API_TOKEN']
	timenow = Time.now.strftime("%Y%m%d")
	response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{q}", :context => "#{context}"}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
	return response
end


# Slack handler for when a reaction is clicked
client.on :reaction_added do |data|

	puts "Reaction is added: #{data.inspect}"
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])

		message_ts = data['item']['ts']
		message_channel = data['item']['channel']
		reaction_name = data['reaction']
		puts "SESSIONS: #{sessions.inspect}" if DEBUG_MODE

		puts "#{data['user']} just added a #{reaction_name} to #{message_channel} at #{message_ts}" if DEBUG_MODE
		user_selected = "#{sessions[data['user']][message_channel][message_ts][reaction_name]}"
		puts text if DEBUG_MODE
		client.message channel: data['item']['channel'], text: "User selected-> #{text}!" if DEBUG_MODE

		# TODO: message Wit with corresponding message selected (user_selected)
	end
	
end

# General Message handler
# TODO: Currently generating unique session_id per call (per second). Not sure why, but I get low confidence back when I use an existing session and get no matches from Wit.ai
client.on :message do |data|
	if data['user'] != CHIMEBOT_ID
		session_id = get_user_session(data['user'])
		client.typing channel: data['channel']
		
		response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}", :context => ""}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
		# client.message channel: data['channel'], text: "#{response.to_s}" if DEBUG_MODE
		puts "USER MESSAGE: #{data['text']}" if DEBUG_MODE
		puts "Response from WIT: #{response.inspect}" if DEBUG_MODE
		puts "RESPONSE TYPE====== #{response['type']}" if DEBUG_MODE
		case response["type"]
		when "msg"
			puts "Sending to client: #{response['msg']}" if DEBUG_MODE
			client.message channel: data['channel'], text: "#{response["msg"]}"
		when "action"
			action_name = response["action"]
			puts response.inspect if DEBUG_MODE
		when "merge"
			puts "BEGIN MERGE====="
			puts response.inspect if DEBUG_MODE
		when "stop"
			puts "go to stop" if DEBUG_MODE
			new_response = HTTParty.post('https://api.wit.ai/converse?', :query => {:v => '#{timenow}',:session_id => session_id, :q =>"#{data.text}", :context => ""}, :headers => {"Authorization" => "Bearer #{api_key_wit}"})
			puts "GOT STOP: #{new_response.inspect}" if DEBUG_MODE
		else
			puts "None matched" if DEBUG_MODE
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
				sessions[session_id] = {} if !sessions.key? session_id
				reply_text = response["quickreplies"][i]
				puts "add emoji: #{emojis[i]} on #{chatbot_response.channel} at #{chatbot_response.ts}" if DEBUG_MODE
				web_client.reactions_add(name: emojis[i], channel: chatbot_response.channel, timestamp: chatbot_response.ts)
				sessions[session_id][chatbot_response.channel] = {} if !sessions[session_id].key? chatbot_response.channel
				sessions[session_id][chatbot_response.channel][chatbot_response.ts] = {} if !sessions[session_id][chatbot_response.channel].key? chatbot_response.ts
				puts "SESSION PRINT: #{sessions.inspect}" if DEBUG_MODE
				sessions[session_id][chatbot_response.channel][chatbot_response.ts][emojis[i]] = reply_text
				
			end
			
		end
		
	end
end
client.start!
