function routing::inject_community (
  Hash[Routing::Asn, Routing::Peer] $peers,
  String $origin = '20144',
) >> Hash[Routing::Asn, Routing::Peer] {
  $location_id = routing::location_id()
  Hash($peers.map |$asn, $peer| {
      $loc_community = [
        "${origin}:${asn}",
        "${origin}:${location_id}:${asn}",
      ]
      $communities = 'community' in $peer ? {
        false   => $loc_community,
        default => $peer['communities'] + $loc_community,
      }
      [$asn, $peer.merge('communities' => $communities)]
  })
}
