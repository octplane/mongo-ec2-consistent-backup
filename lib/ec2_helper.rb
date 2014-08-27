require 'open-uri'
require 'json'
require 'fog'

# Support IAM instance profiles
class EC2Helper

  # Need access_key_id, secret_access_key
  def initialize(aki, sak)
    @aki = aki
    @sak = sak
    @gettoken = false
  end

  def connection
    if token.nil?
      {:provider => 'AWS', :aws_access_key_id => access_key, :aws_secret_access_key => secret_key, :region => region}
    else
      {:provider => 'AWS', :aws_access_key_id => access_key, :aws_secret_access_key => secret_key, :aws_session_token => token, :region => region}
    end
  end

  def access_key
    if @aki.nil?
      creds = get_creds_from_metadata
      @aki = creds['AccessKeyId']
      @gettoken = true
    end
    @aki
  end

  def secret_key
    if @sak.nil?
      creds = get_creds_from_metadata
      @sak = creds['SecretAccessKey']
      @gettoken = true
    end
    @sak
  end

  def token
    get_creds_from_metadata['Token]'] if @gettoken
  end

  def iam_role
    open('http://169.254.169.254/latest/meta-data/iam/security-credentials').readline
  end

  def instance_id
    open('http://169.254.169.254/latest/meta-data/instance-id').readline
  end

  def region
    open('http://169.254.169.254/latest/meta-data/placement/availability-zone').readline[0..-2]
  end

  def availability_zone
    open('http://169.254.169.254/latest/meta-data/placement/availability-zone').readline
  end
  
  private

  def get_creds_from_metadata
    begin
      JSON.parse(open("http://169.254.169.254/latest/meta-data/iam/security-credentials/#{iam_role}").read)
    rescue OpenURI::HTTPError => e
      { 'AccessKeyId' => nil, 'SecretAccessKey' => nil, 'Token' => nil }
    end
  end
end