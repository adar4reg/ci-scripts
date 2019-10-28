require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module Authorize

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Drive API Ruby Quickstart'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE

  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def initialize
    @service = Google::Apis::DriveV3::DriveService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

end

