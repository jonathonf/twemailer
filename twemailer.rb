require 'twitter'
require 'pony'

# Open file storing last seen tweet id
begin
  file = File.open("lastseen.id", 'r')
  # set to get timeline since last seen id
  @timeline_option = {:since_id => file.read.to_i}
  file.close
rescue # otherwise set default option to get last 20 in timeline
  @timeline_option = {}
end

# Open the config file for user options
begin
  @Conf = YAML.load_file("user.config")
rescue
  puts "No configuration file, or incorrect format. Please check your config file."
end

# Set up Twitter OAuth configuration
Twitter.configure do |config|
  config.consumer_key = @Conf['consumer_key']
  config.consumer_secret = @Conf['consumer_secret']
  config.oauth_token = @Conf['oauth_token']
  config.oauth_token_secret = @Conf['oauth_token_secret']
end

# Create new Twitter client instance
client = Twitter::Client.new

# Get the timeline data
@timelinedata = client.home_timeline( options = @timeline_option )

if @timelinedata.length!=0 then # there are new updates
  # so iterate through the array of tweets
  @timelinedata.each do |status|
    emailfrom = status['user']['name'] + " <" + status['user']['screen_name'] + "@twitter.com>"
    emailsubject = "Update posted " + status['created_at'][0..15]
    emailtext = status['text']
    puts "Sending tweet id " + status['id'].to_s
    Pony.mail(:to => @Conf['email'], :from => emailfrom,
              :subject => emailsubject, :body => emailtext,
              :headers => {"X-Tweet-ID" => status['id'].to_s})
end

  # set the last seen to the first returned tweet; this is the last one received
  # write out last seen to a file for next time
  file = File.new("lastseen.id",'w')
  file.write @timelinedata[0]['id']
  file.close
#else
#  puts "No new tweets"
end

