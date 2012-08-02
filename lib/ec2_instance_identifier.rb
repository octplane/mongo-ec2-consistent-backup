require 'resolv'
require 'fog'

class EC2InstanceNotFoundException < Exception; end
# Fetch an instance from its private ip address
class EC2InstanceIdentifier
  # Need access_key_id, secret_access_key
  def initialize(aki, sak)
    @compute = Fog::Compute.new({:provider => 'AWS', :aws_access_key_id => aki, :aws_secret_access_key => sak})
  end
  # Returns the instance corresponding to the provided hostname
  def get_instance(hostname)
    ip = Resolv.getaddress(hostname)
    instance = @compute.servers.all().find { |i| i.private_ip_address  == ip || i.public_ip_address == ip }
    raise InstanceNotFoundException.new(hostname) if ! instance
    return instance
  end
end

if __FILE__ == $0
  require 'trollop'
  require 'pp'
  opts = Trollop::options do
    opt :access_key_id, "Access Key Id for AWS", :type => :string, :required => true
    opt :secret_access_key, "Secret Access Key for AWS", :type => :string, :required => true
    opt :hostname, "Hostname to look for. Should resolve to a local EC2 Ip", :type => :string, :required => true
  end

  eii = EC2InstanceIdentifier.new(opts[:access_key_id], opts[:secret_access_key])
  pp eii.get_instance(opts[:hostname])

end