#used to validate peer data
type Routing::Peer = Struct[{
    addr4             => Optional[Array[Stdlib::IP::Address::V4]],
    addr6             => Optional[Array[Stdlib::IP::Address::V6]],
    desc              => NotUndef[String[1,140]],
    communities       => Optional[Array[Routing::Community]],
    multihop          => Optional[Integer[1,255]],
    prepend           => Optional[Integer[1,255]],
    default_originate => Optional[Boolean],
    enforce_first_as  => Optional[Boolean],
    inbound_routes    => Optional[
    Enum['all', 'none', 'default', 'v6default', 'v4default']]
}]
