require 'resolv'
require 'fog'
$: << File.join(File.dirname(__FILE__), "../lib")
require 'ec2_helper'

class EC2InstanceNotFoundException < Exception; end

# Fetch an instance from its private ip address
class EC2InstanceIdentifier
  def initialize(aki, sak)
    @ec2 = EC2Helper.new(aki, sak)
    @compute = Fog::Compute.new(@ec2.connection)
  end

  # Returns the instance corresponding to the provided hostname
  def get_instance(hostname)
    if hostname.nil?
      @ec2.instance_id
    else
      ip = Resolv.getaddress(hostname)
      instance = @compute.servers.all().find { |i| i.private_ip_address  == ip || i.public_ip_address == ip }
      raise InstanceNotFoundException.new(hostname) if ! instance
      instance.id
    end
  end
end

if __FILE__ == $0
  require 'trollop'
  require 'pp'
  opts = Trollop::options do
    opt :access_key_id, "Access Key Id for AWS", :type => :string
    opt :secret_access_key, "Secret Access Key for AWS", :type => :string
    opt :hostname, "Hostname to look for. Should resolve to a local EC2 Ip", :type => :string
  end

  eii = EC2InstanceIdentifier.new(opts[:access_key_id], opts[:secret_access_key])
  pp eii.get_instance(opts[:hostname])
end