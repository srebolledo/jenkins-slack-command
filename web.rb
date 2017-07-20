require 'sinatra'
require 'rest-client'
require 'json'
require 'slack-notifier'

get '/' do
  "This is a thing"
end

post '/' do

  # Verify all environment variables are set
  return [403, "No slack token setup"] unless slack_token = ENV['SLACK_TOKEN']
  return [403, "No jenkins url setup"] unless jenkins_url= ENV['JENKINS_URL']
  return [403, "No jenkins token setup"] unless jenkins_token= ENV['JENKINS_TOKEN']
  return [403, "No jenkins username setup"] unless jenkins_username= ENV['JENKINS_USERNAME']
  return [403, "No jenkins user token setup"] unless jenkins_user_token= ENV['JENKINS_USER_TOKEN']

  # Verify slack token matches environment variable
  return [401, "No authorized for this command"] unless slack_token == params['token']

  # Split command text
  text_parts = params['text'].split(' ')

  # Split command text - job
  job = text_parts[0]

  # Split command text - parameters
  parameters = []
  if text_parts.size > 1
    all_params = text_parts[1..-1]
    all_params.each do |p|
      p_thing = p.split('=')
      parameters << { :name => p_thing[0], :value => p_thing[1] }
    end
  end

  
  # Jenkins url
  jenkins_job_url = "#{jenkins_url}/job/#{job}"

  # Get next jenkins job build number
  
  resp = RestClient::Request.execute method: :get, url: "#{jenkins_job_url}/api/json", user: jenkins_username, password: jenkins_token
  resp_json = JSON.parse( resp.body )
  next_build_number = resp_json['nextBuildNumber']

  # Make jenkins request
  json = JSON.generate( {:parameter => parameters} )
  resp = RestClient::Request.execute method: :post, url: "#{jenkins_job_url}/build?token=#{jenkins_token}", :json => json, user: jenkins_username, password: jenkins_token
  resp = RestClient.post 

  # Build url
  build_url = "#{jenkins_job_url}/#{next_build_number}"

  slack_webhook_url = ENV['SLACK_WEBHOOK_URL']
  if slack_webhook_url
    notifier = Slack::Notifier.new slack_webhook_url
    notifier.ping "Started job '#{job}' - #{build_url}"
  end

  build_url

end
