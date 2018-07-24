# encoding: utf-8

require 'resolv'

# Uses the core Ruby library to do a lookup on a host and return the address
# plus if it actually exists or not
class DNSLookup
  def initialize(host)
    @host = host
  end

  def exists?
    !lookup.empty?
  end

  def address
    return nil unless exists?
    lookup.first.address.to_s
  end

  private

  def lookup
    @lookup ||= Resolv::DNS.new.getresources(@host, Resolv::DNS::Resource::IN::A)
  end
end
