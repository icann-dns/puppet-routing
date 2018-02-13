# == Class: routing
#
class routing (
  Routing::Asn          $my_asn,
  Tea::Ipv4             $router_id,
  Routing::Daemon       $daemon                   = $::routing::params::daemon,
  Array[Tea::Ipv4_cidr] $networks4                = [],
  Array[Tea::Ipv6_cidr] $networks6                = [],
  Array[Tea::Ipv4_cidr] $failsafe_networks4       = [],
  Array[Tea::Ipv6_cidr] $failsafe_networks6       = [],
  Array[Tea::Ipv4_cidr] $rejected_v4              = [],
  Array[Tea::Ipv6_cidr] $rejected_v6              = [],
  Boolean               $reject_bogons_v4         = true,
  Boolean               $reject_bogons_v6         = true,
  Boolean               $failover_server          = false,
  Boolean               $enable_advertisements    = true,
  Boolean               $enable_advertisements_v4 = true,
  Boolean               $enable_advertisements_v6 = true,
  Boolean               $enable_nagios            = false,
  Boolean               $fib_update               = true,
  Hash[Routing::Asn, Routing::Peer] $peers        = {},
) inherits routing::params {

  $routing_class = $daemon ? {
    'quagga' => '::quagga::bgpd',
    default  => '::openbgpd',
  }

  #The zone_status_errors fact comes from puppet-dns
  if defined('$::zone_status_errors') and ($::zone_status_errors == true or $::zone_status_errors == 'true') {
    $_failover_server = true
  } else {
    $_failover_server = $failover_server
  }

  class { $routing_class:
    my_asn                   => $my_asn,
    router_id                => $router_id,
    networks4                => $networks4,
    networks6                => $networks6,
    failsafe_networks4       => $failsafe_networks4,
    failsafe_networks6       => $failsafe_networks6,
    rejected_v4              => $rejected_v4,
    rejected_v6              => $rejected_v6,
    reject_bogons_v4         => $reject_bogons_v4,
    reject_bogons_v6         => $reject_bogons_v6,
    failover_server          => $_failover_server,
    enable_advertisements    => $enable_advertisements,
    enable_advertisements_v4 => $enable_advertisements_v4,
    enable_advertisements_v6 => $enable_advertisements_v6,
    fib_update               => $fib_update,
    peers                    => $peers,
  }

  if $enable_nagios and $enable_advertisements {
    $peers.each |Routing::Asn $asn, Routing::Peer $peer| {
      if $enable_advertisements_v4 and has_key($peer, 'addr4') {
        if $failover_server {
          $routes4 = $failsafe_networks4
        } else {
          $routes4 = concat($networks4, $failsafe_networks4)
        }
        $routes4_check_arg = join($routes4, ' ')
        $peer['addr4'].each |Tea::Ip_address $addr| {
          @@nagios_service {"${::fqdn}_BGP_NEIGHBOUR_${addr}":
            ensure              => present,
            use                 => 'generic-service',
            host_name           => $::fqdn,
            service_description => "BGP_NEIGHBOUR_${addr}",
            check_command       => "check_nrpe_args!check_bgp!${addr}!${routes4_check_arg}",
          }
        }
      }
      if $enable_advertisements_v6 and has_key($peer, 'addr6') {
        if $failover_server {
          $routes6 = $failsafe_networks6
        } else {
          $routes6 = concat($networks6, $failsafe_networks6)
        }
        $routes6_check_arg = join($routes6, ' ')
        $peer['addr6'].each |Tea::Ip_address $addr| {
          @@nagios_service {"${::fqdn}_BGP_NEIGHBOUR_${addr}":
            ensure              => present,
            use                 => 'generic-service',
            host_name           => $::fqdn,
            service_description => "BGP_NEIGHBOUR_${addr}",
            check_command       => "check_nrpe_args!check_bgp!${addr}!${routes6_check_arg}",
          }
        }
      }
    }
  }
}
