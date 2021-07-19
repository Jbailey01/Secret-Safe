require 'rest-client'
require 'json'
require_relative 'dss_common'

Puppet::Functions.create_function(:'dss_get_secret') do
    dispatch :dss_get_secret do
      param 'String', :host
      param 'String', :secret_uri
      param 'String', :app_name
      param 'String', :api_key
    end
  
    def dss_get_secret(host, secret_uri, app_name, api_key)
      @base_api_url = get_base_api_url(host)
      token = get_token(@base_api_url, app_name, api_key)
      read_secret(token, secret_uri)
    end

    def read_secret(token, secret_uri)
      full_secret_uri = @base_api_url + 'secret/' + secret_uri
      get_secret_headers = {'Authorization': 'Bearer ' + token}
    
      secret_response = RestClient::Request.execute(
        :url => full_secret_uri, 
        :method => :get,
        :headers => get_secret_headers
      )
    end
end
