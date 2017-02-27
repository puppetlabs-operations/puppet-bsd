# Module: PuppetX::BSD::Hostname_if::Inet
#
# Responsible for processing interface inet and inet6 addressing in the
# hostname_if(5) format found on OpenBSD.
#
# Argument passed to #new must be a String of an IP address or an Array of IP
# addresses, or strings of dynamic addressing methods (rtsol, inet6 autoconf or dhcp).
#

require 'puppet/util/package'

begin
  require 'ipaddress'
rescue => e
  puts e.message
  puts e.backtrace.inspect
end

module PuppetX
  module BSD
    class Hostname_if
      class Inet
        include Puppet::Util::Package

        def initialize(addresses)
          unless [String, Array].include? addresses.class
            raise TypeError, "expected String or Array, is #{addresses.class}"
          end

          @addrs = [addresses].flatten

          # Used to determine if the address has already been set.  If true,
          # then the address should be processed as an alias.
          @ipset  = false
          @ip6set = false
        end

        def process
          @addrs.each do |a|
            # Return the dynamic address assignment if found
            if a =~ /^(dhcp)$/
              yield a
            elsif a =~ /^(rtsol|inet6 autoconf)$/
              kernelversion = Facter.value('kernelversion')
              if versioncmp(kernelversion, '5.6') <= 0
                yield 'rtsol'
              else
                yield 'inet6 autoconf'
              end
            else
              begin
                ip = IPAddress a
                if ip.ipv6?
                  line = ['inet6']
                  line << 'alias' if @ip6set
                  line << ip.compressed
                  line << ip.prefix
                  @ip6set = true
                elsif ip.ipv4?
                  line = ['inet']
                  line << 'alias' if @ipset
                  line << ip.address
                  line << ip.netmask
                  line << 'NONE'
                  @ipset = true
                end
                yield line.join(' ') if line
              rescue => e
                raise "addr is #{a} of class #{a.class}: #{e.message}"
              end
            end
          end
        end
      end
    end
  end
end
