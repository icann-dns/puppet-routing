# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'openbgpd class failsafe networks router' do
  router1               = find_host_with_role(:router1)
  router2               = find_host_with_role(:router2)
  router1_ip            = '10.255.255.2'
  router1_ip6           = '2001:db8:1::1'
  router1_asn           = '64496'
  router2_ip            = '10.255.255.3'
  router2_ip6           = '2001:db8:1::2'
  router2_asn           = '64497'
  ipv6_network          = '2001:db8:2::/48'
  ipv4_network          = '10.0.0.0/24'
  ipv6_failsafe_network = '2001:db8::/32'
  ipv4_failsafe_network = '10.0.0.0/23'
  on(router1, "ifconfig em1 inet6 #{router1_ip6} prefixlen 64", acceptable_exit_codes: [0, 2])
  on(router2, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
  on(router2, "ip -6 addr add #{router2_ip6}/64 dev enp0s8", acceptable_exit_codes: [0, 2])
  context 'basic' do
    pp1 = <<-PUPPET_POLICY
    class { '::openbgpd':
      my_asn => #{router1_asn},
      router_id => '#{router1_ip}',
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'all'
          }
      }
    }
    PUPPET_POLICY
    pp2 = <<-PUPPET_POLICY
    class { '::openbgpd':
      my_asn             => #{router2_asn},
      router_id          => '#{router2_ip}',
      networks4          => [ '#{ipv4_network}'],
      networks6          => [ '#{ipv6_network}'],
      failsafe_networks4 => [ '#{ipv4_failsafe_network}' ],
      failsafe_networks6 => [ '#{ipv6_failsafe_network}' ],
      peers => {
        #{router1_asn} => {
          'addr4'       => ['#{router1_ip}'],
          'addr6'       => ['#{router1_ip6}'],
          'desc'        => 'TEST Network',
          'prepend'     => 3,
          'communities' => ['no-export', '999:100'],
          }
      }
    }
    PUPPET_POLICY
    it 'work with no errors' do
      apply_manifest(pp1, catch_failures: true)
      apply_manifest_on(router2, pp2, catch_failures: true)
    end
    it 'r1 clean puppet run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    it 'r2 clean puppet run' do
      expect(apply_manifest_on(router2, pp2, catch_failures: true).exit_code).to eq 0
    end
    describe service('openbgpd') do
      it { is_expected.to be_running }
    end
    describe process('bgpd') do
      its(:user) { is_expected.to eq '_bgpd' }
      it { is_expected.to be_running }
    end
    describe port(179) do
      it { is_expected.to be_listening }
    end
    describe command("ping -c 1 #{router2_ip}") do
      its(:exit_status) { is_expected.to eq 0 }
    end
    describe command("ping6 -I em1 -c 1 #{router2_ip6}") do
      its(:exit_status) { is_expected.to eq 0 }
    end
    describe command("bgpctl show neighbor #{router2_ip}") do
      let(:pre_command) { 'sleep 120' }

      its(:stdout) do
        is_expected.to match(
          %r{BGP neighbor is #{router2_ip}, remote AS #{router2_asn}.*?Established}m
        )
      end
    end
    describe command("bgpctl show neighbor #{router2_ip6}") do
      its(:stdout) do
        is_expected.to match(
          %r{BGP neighbor is #{router2_ip6}, remote AS #{router2_asn}.*?Established}m
        )
      end
    end
    describe command("bgpctl show rib peer-as #{router2_asn}") do
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv4_network}\s+#{router2_ip}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv4_failsafe_network}\s+#{router2_ip}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv6_network}\s+#{router2_ip6}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv6_failsafe_network}\s+#{router2_ip6}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
    end
    describe command('bgpctl show rib community NO_EXPORT') do
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv4_failsafe_network}\s+#{router2_ip}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv6_failsafe_network}\s+#{router2_ip6}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
    end
    describe command('bgpctl show rib community 999:100') do
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv4_network}\s+#{router2_ip}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{ipv4_failsafe_network}\s+#{router2_ip}\s+\d+\s+\d+\s+(#{router2_asn}\s+){4}i}
        )
      end
    end
  end
end
