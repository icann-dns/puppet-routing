# @summary convert the un-locde of a node to a base36 integer
function routing::location_id() {
  $un_locode = $facts['networking']['fqdn'].split(/\./)[1].regsubst('-', '', 'G').downcase()
  Integer(inline_template('<%= Integer(@un_locode, 36) %>'))
}
