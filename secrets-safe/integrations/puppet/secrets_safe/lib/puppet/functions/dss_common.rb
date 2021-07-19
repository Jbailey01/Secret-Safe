require 'rest-client'
require 'json'

def get_token(base_api_url, app_name, api_key)
    token_url = base_api_url + 'connect/api_key_token'
    payload = {'application_name': app_name, 'api_key': api_key}
    payload_str = JSON.generate(payload)
    headers = {'accept': 'text/plain', 'Content-Type': 'application/json'}

    response = RestClient::Request.execute(
        :url => token_url, 
        :method => :post,
        :payload => payload_str,
        :headers => headers
    )
    response_json = JSON.parse(response.body)
    token = response_json['access_token']
end

def get_base_api_url(host)
    host + '/secretssafe/api/v1/'
end