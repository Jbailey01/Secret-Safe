require 'rest-client'
require 'json'
require_relative 'dss_common'

Puppet::Functions.create_function(:'dss_create_secret_with_value') do
    dispatch :dss_create_secret_with_value do
      param 'String', :host
      param 'String', :secret_uri
      param 'String', :app_name
      param 'String', :api_key
      param 'String', :secret_string
    end
  
    def dss_create_secret_with_value(host, secret_uri, app_name, api_key, secret_string)
      @base_api_url = get_base_api_url(host)
      token = get_token(@base_api_url, app_name, api_key)
      create_secret_from_string(token, secret_uri, secret_string)
    end

    def create_secret_from_string(token, secret_uri, secret_string)
        full_secret_uri = @base_api_url + 'secret/' + secret_uri
        get_secret_headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'text/plain'}
        
        secret_response = RestClient::Request.execute(
          :url => full_secret_uri, 
          :method => :post,
          :headers => get_secret_headers,
          :payload => secret_string
        )
      end      
end
