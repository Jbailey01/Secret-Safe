require 'rest-client'
require 'json'
require_relative 'dss_common'

Puppet::Functions.create_function(:'dss_create_secret_with_generator') do
    dispatch :dss_create_secret_with_generator do
      param 'String', :host
      param 'String', :secret_uri
      param 'String', :app_name
      param 'String', :api_key
      param 'String', :generator_name
    end
  
    def dss_create_secret_with_generator(host, secret_uri, app_name, api_key, generator_name)
      @base_api_url = get_base_api_url(host)
      token = get_token(@base_api_url, app_name, api_key)              
      create_secret_from_generator(token, secret_uri, generator_name)
    end

    def create_secret_from_generator(token, secret_uri, generator_name)
      full_secret_uri = @base_api_url + 'secret/' + secret_uri
      full_secret_uri = full_secret_uri + '?generator=' + generator_name
      get_secret_headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'text/plain'}
        
      secret_response = RestClient::Request.execute(
        :url => full_secret_uri, 
        :method => :post,
        :headers => get_secret_headers
      )
    end
      
end
