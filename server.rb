require 'sinatra'
require 'httparty'
require 'securerandom'
require 'twilio-ruby'
require 'optimizely'
require 'pry'

# STEP 1: Add the Optimizely Full Stack Ruby gem
# STEP 2: Require the Optimizely gem
# STEP 3: Include the twilio account SID, auth token and phone number below

# => Log into Twilio and access the account SID, token, and number
TWILIO_NUMBER = '+16194042427'
TWILIO_ACCOUNT_SID = ''
TWILIO_AUTH_TOKEN = ''

# Optimizely Setup

# Step 4: Replace this url with your own Optimizely Project

DATAFILE_URL = 'https://cdn.optimizely.com/public/6566831207/s/10687614047_10687614047.json'

DATAFILE_URI_ENCODED = URI(DATAFILE_URL)

datafile = HTTParty.get(DATAFILE_URI_ENCODED).body
optimizely_client = Optimizely::Project.new(datafile)
#binding.pry

# => Step 5: Use a library, such as HTTParty, to get grab the datafile from the CDN
#         https://github.com/jnunemaker/httparty#examples
#         example: response = HTTParty.get('http://api.stackexchange.com/2.2/questions?site=stackoverflow').body
#         The above line will return the body of the http request
#         NOTE: use the uri encoded url shown above :)

# => Step 6: Initialize the Optimizely SDK using the json retrieved from step 4
#		  https://developers.optimizely.com/x/solutions/sdks/reference/?language=ruby

# => Initializing the Twilio client to send sms messages
# => https://www.twilio.com/docs/libraries/ruby
TWILIO_CLIENT = Twilio::REST::Client.new TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN

get '/' do
  puts "[CONSOLE LOG]"
	'Welcome to the SE Full Stack training'
  # puts "[CONSOLE LOG] Client: #{optimizely_client}"
end

# => GET endpoint to receive messages, this should be setup as a webhook in Twilio
# => anytime twilio receives a message on our number, Twilio will make a request to this endpoint
get '/sms' do
  # => Getting the number that texted the sms service
	sender_number = params[:From]

  # => Getting the message that was sent to the service
  # => We could use this to understand what the user said, and create a conversational dialog
	text_body = params[:Body]

  # => Outputing the number and text body to the ruby console
	puts "[CONSOLE LOG] New message from #{sender_number}"
	puts "[CONSOLE LOG] They said #{text_body}"
	puts "[CONSOLE LOG] Let's respond!"

	# =>  Randomly generate a new User ID to demonstrate bucketing
	# =>  Alternatively, you can use sender_number as the user ID, however due to deterministic bucketing using a single user id will always return the same variation
	user_id = SecureRandom.uuid
  variation_key = optimizely_client.activate('twilio_test', user_id)
    if variation_key == 'a'
      send_sms "Hey you got variation #{variation_key}", sender_number
      optimizely_client.track('cool_event', user_id)
    elsif variation_key == 'b'
      send_sms "Hey you got variation #{variation_key}", sender_number
      optimizely_client.track('cool_event', user_id)
    else
  # execute default code
    end

	# => STEP 7: Implement an Optimizely Full Stack experiment, or feature flag (with variables)
	# => Example, test out different messages in your response
	# => Using the helper function to reply to the number who messaged the sms service
  # => example: send_sms "Hey this is a response!" sender_number

end

# => BONUS: Implement a Optimizely webhooks to receive updates when your datafile changes & reinitialize the SDK
post '/webhook' do
  puts "[CONSOLE LOG] datafile updated, reinitializing SDK"
  datafile = HTTParty.get(DATAFILE_URI_ENCODED).body
  optimizely_client = Optimizely::Project.new(datafile)
end

# =>  Helper function to send a text message
# =>  The first parameter is the content of the text you wish to send
# =>  The second parameter is the number you wish to send the text to
def send_sms body, number
	TWILIO_CLIENT.api.account.messages.create(
      from: TWILIO_NUMBER,
      to: number,
      body: body
    )
end
