# = Class: bsd::network
#
# Configures basic network paramaters on some BSD systems.
#
# == Parameters:
#
# $v4gateway:: A string containing the IPv4 default gateway router.
# $v6gateway:: A string containing the IPv6 default gateway router.
# $v4forwarding:: Boolean to turn on/off IPv4 traffic forwarding functionality.
# $v6forwarding:: Boolean to turn on/off IPv6 traffic forwarding functionality.
#
# = Authors:
#
#   Zach Leslie <xaque208@gmail.com>
#
# Copyright 2013 Puppet Labs
#
class bsd::network (
  Optional[IP::Address::V4] $v4gateway = undef,
  Optional[IP::Address::V6] $v6gateway = undef,
  Boolean $v4forwarding                = false,
  Boolean $v6forwarding                = false,
) {

  # Options common to both FreeBSD and OpenBSD
  if $v4forwarding {
    sysctl { 'net.inet.ip.forwarding':
      ensure => present,
      value  => '1',
    }
  } else {
    sysctl { 'net.inet.ip.forwarding':
      ensure => present,
      value  => '0',
    }
  }

  if $v6forwarding {
    sysctl { 'net.inet6.ip6.forwarding':
      ensure => present,
      value  => '1',
    }
  } else {
    sysctl { 'net.inet6.ip6.forwarding':
      ensure => present,
      value  => '0',
    }
  }

  case $::osfamily {
    'OpenBSD': {
      # TODO Manage the live state of the route table

      # Manage the /etc/mygate file
      # TODO Sanitize input here
      if $v4gateway and $v6gateway {
        $mygate = [$v4gateway,$v6gateway]
      } elsif $v4gateway {
        $mygate = [$v4gateway]
      } elsif $v6gateway {
        $mygate = [$v6gateway]
      } else {
        $mygate = []
      }

      file { '/etc/mygate':
        owner   => 'root',
        group   => '0',
        mode    => '0644',
        content => inline_template("<%= @mygate.join(\"\n\") + \"\n\" %>"),
      }
    }
    'FreeBSD': {
      Shellvar {
        target => '/etc/rc.conf',
        notify => Service['routing'],
      }

      # Should we enable IPv4 forwarding?
      if $v4forwarding {
        shellvar { 'gateway_enable':
          value => 'YES',
        }
      } else {
        shellvar { 'gateway_enable':
          ensure => absent,
          value  => 'YES',
        }
      }

      # Should we enable IPv6 forwarding?
      if $v6forwarding {
        shellvar { 'ipv6_gateway_enable':
          value => 'YES',
        }
      } else {
        shellvar { 'ipv6_gateway_enable':
          ensure => absent,
          value  => 'YES',
        }
      }

      # What is our IPv4 default router?
      if $v4gateway {
        shellvar { 'defaultrouter':
          value => $v4gateway,
        }
      } else {
        shellvar { 'defaultrouter':
          ensure => absent,
          value  => $v4gateway,
        }
      }

      # What is our IPv6 default router?
      if $v6gateway {
        shellvar { 'ipv6_defaultrouter':
          value => $v6gateway,
        }
      } else {
        shellvar { 'ipv6_defaultrouter':
          ensure => absent,
          value  => $v6gateway,
        }
      }

      service { 'routing':
        hasstatus => false,
      }
    }
    default: {
      notify { 'Not supported': }
    }
  }
}
