# == Class: routing
#
# @param my_asn The local ASN number
# @param router_id The router_id
# @param networks4 List of v4 networks to advertise
# @param failsafe_networks4 List of v4 failsafe networks to advertise
# @param networks6 List of v6 networks to advertise
# @param failsafe_networks6 List of v6 failsafe networks to advertise
# @param rejected_v4 list of v4 networks to reject
# @param rejected_v6 list of v6 networks to reject
# @param reject_bogons_v4 list of v4 bogons to reject
# @param reject_bogons_v6 list of v6 bogons to reject
# @param operational If this is false then the node will be marked as a failover server
# @param failover_server If this is a failover server.  Note that the zone_status_errors
#   and the operational parameter both take precedence over this parameter
# @param enable_advertisements weather we should advertise bgp networks
# @param enable_advertisements_v4 weather we should advertise bgp v4networks
# @param enable_advertisements_v6 weather we should advertise bgp v6networks
# @param fib_update update the local fib
# @param peers A hash of peers
class routing (
  Routing::Asn          $my_asn,
  Stdlib::IP::Address::V4              $router_id,
  Array[Stdlib::IP::Address::V4::CIDR] $networks4                = [],
  Array[Stdlib::IP::Address::V6::CIDR] $networks6                = [],
  Array[Stdlib::IP::Address::V4::CIDR] $failsafe_networks4       = [],
  Array[Stdlib::IP::Address::V6::CIDR] $failsafe_networks6       = [],
  Array[Stdlib::IP::Address::V4::CIDR] $rejected_v4              = [],
  Array[Stdlib::IP::Address::V6::CIDR] $rejected_v6              = [],
  Boolean                              $reject_bogons_v4         = true,
  Boolean                              $reject_bogons_v6         = true,
  Boolean                              $operational              = true,
  Boolean                              $failover_server          = false,
  Boolean                              $enable_advertisements    = true,
  Boolean                              $enable_advertisements_v4 = true,
  Boolean                              $enable_advertisements_v6 = true,
  Boolean                              $fib_update               = true,
  Hash[Routing::Asn, Routing::Peer]    $peers        = {},
) {
  # The zone_status_errors fact comes from puppet-dns and
  # TODO: ensure zone_status_errors is a real bool
  if Boolean($facts['zone_status_errors']) or !$operational {
    $_failover_server = true
  } else {
    $_failover_server = $failover_server
  }

  class { 'quagga::bgpd':
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
}
