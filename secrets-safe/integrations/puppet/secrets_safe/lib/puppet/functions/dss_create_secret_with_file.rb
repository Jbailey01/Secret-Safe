require 'rest-client'
require 'json'
require_relative 'dss_common'

Puppet::Functions.create_function(:'dss_create_secret_with_file') do
    dispatch :dss_create_secret_with_file do
      param 'String', :host
      param 'String', :secret_uri
      param 'String', :app_name
      param 'String', :api_key
      param 'String', :file_name
    end
  
    def dss_create_secret_with_file(host, secret_uri, app_name, api_key, file_name)
      @base_api_url = get_base_api_url(host)
      token = get_token(@base_api_url, app_name, api_key)              
      create_secret_from_file(token, secret_uri, file_name)
    end

    def create_secret_from_file(token, secret_uri, file_path)
        full_secret_uri = @base_api_url + 'secret/' + secret_uri
        get_secret_headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/octet-stream'}
        file = File.open(file_path)
        secret_response = RestClient::Request.execute(
          :url => full_secret_uri, 
          :method => :post,
          :headers => get_secret_headers,
          :payload => file
        )
    end
      
end
