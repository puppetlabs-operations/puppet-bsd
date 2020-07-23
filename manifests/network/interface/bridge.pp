# Define: bsd::network::interface::bridge
#
# Handle the creation and configuration of bridge(4) interfaces.
#
define bsd::network::interface::bridge (
  Array $interface,
  $ensure      = 'present',
  $description = undef,
  $raw_values  = undef,
) {

  $if_name = $name
  validate_re($if_name, ['bridge'])

  validate_re(
    $ensure,
    '(up|down|present|absent)',
    '$ensure can only be one of up, down, present, or absent'
  )

  $config = {
    interface => $interface,
  }

  case $facts['kernel'] {
    'FreeBSD': {
      $bridge_options = get_rc_conf_bridge($config)

      bsd::network::interface { $if_name:
        ensure      => $ensure,
        description => $description,
        options     => $bridge_options,
        parents     => flatten([$interface]),
      }
    }
    'OpenBSD': {
      $bridge_ifconfig = get_hostname_if_bridge($config)

      if $raw_values {
        $bridge_values = concat([$bridge_ifconfig], $raw_values)
      } else {
        $bridge_values = [$bridge_ifconfig]
      }

      bsd::network::interface { $if_name:
        ensure      => $ensure,
        description => $description,
        raw_values  => $bridge_values,
        parents     => $interface,
      }
    }
    default: {
      fail('unhandled BSD for bridge interface, please help add support')
    }
  }
}
