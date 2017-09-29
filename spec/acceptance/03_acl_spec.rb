# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'openbgpd class ACLs ' do
  router1 = find_host_with_role(:router1)
  router2 = find_host_with_role(:router2)
  router1_ip = '10.255.255.2'
  router1_ip6 = '2001:db8:1::1'
  router1_asn = '64496'
  router2_ip = '10.255.255.3'
  router2_ip6 = '2001:db8:1::2'
  router2_asn = '64497'
  ipv6_network = '2001:db8::/32'
  ipv4_network = '10.0.0.0/24'
  additional_v4_network1 = '192.0.2.0/24'
  additional_v6_network1 = '2001:db8:2::/48'
  additional_v4_network2 = '198.51.100.0/24'
  additional_v6_network2 = '2001:db8:3::/48'
  on(router1, "ifconfig em1 inet6 #{router1_ip6} prefixlen 64", acceptable_exit_codes: [0, 2])
  on(router2, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
  on(router2, "ip -6 addr add #{router2_ip6}/64 dev enp0s8", acceptable_exit_codes: [0, 2])
  context 'basic' do
    pp1 = <<-PUPPET_POLICY
    class { '::routing':
      my_asn => #{router1_asn},
      fib_update => false,
      router_id => '#{router1_ip}',
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'none',
          }
      }
    }
    PUPPET_POLICY
    pp2 = <<-PUPPET_POLICY
    class { '::routing':
      my_asn => #{router2_asn},
      fib_update => false,
      router_id => '#{router2_ip}',
      networks4 => [
        '#{ipv4_network}',
        '#{additional_v4_network1}',
        '#{additional_v4_network2}',
        ],
      networks6 => [
        '#{ipv6_network}',
        '#{additional_v6_network1}',
        '#{additional_v6_network2}'
        ],
      peers => {
        #{router1_asn} => {
          'addr4'             => ['#{router1_ip}'],
          'addr6'             => ['#{router1_ip6}'],
          'desc'              => 'TEST Network',
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
    describe command('bgpctl show rib') do
      its(:stdout) { is_expected.not_to match(%r{\b192\.0\.2\.0\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b198\.51\.100\.0\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b0\.0\.0\.0\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network2}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b::\/0\b}) }
    end
  end
  context 'all' do
    pp1 = <<-EOF
    class { '::routing':
      my_asn => #{router1_asn},
      fib_update => false,
      router_id => '#{router1_ip}',
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'all',
          }
      }
    }
    EOF
    it 'appling all acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    describe command("bgpctl show rib peer-as #{router2_asn}") do
      let(:pre_command) { 'sleep 120' }

      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{additional_v4_network1}\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{additional_v4_network2}\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) { is_expected.not_to match(%r{\b0\.0\.0\.0\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{additional_v6_network1}\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{additional_v6_network2}\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) { is_expected.not_to match(%r{\b::\/0\b}) }
    end
  end
  context 'all with rejected networks' do
    pp1 = <<-EOF
    class { '::routing':
      my_asn => #{router1_asn},
      router_id => '#{router1_ip}',
      fib_update => false,
      rejected_v4 => ['#{additional_v4_network1}'],
      rejected_v6 => ['#{additional_v6_network1}'],
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'all',
          }
      }
    }
    EOF
    it 'appling all acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    describe command("bgpctl show rib peer-as #{router2_asn}") do
      let(:pre_command) { 'sleep 120' }

      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network1}\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{additional_v4_network2}\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) { is_expected.not_to match(%r{\b0\.0\.0\.0\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network1}\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+#{additional_v6_network2}\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) { is_expected.not_to match(%r{\b::\/0\b}) }
    end
  end
  context 'default' do
    pp1 = <<-EOF
    class { '::routing':
      my_asn => #{router1_asn},
      fib_update => false,
      router_id => '#{router1_ip}',
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'default',
          }
      }
    }
    EOF
    pp2 = <<-EOF
    class { '::routing':
      my_asn => #{router2_asn},
      fib_update => false,
      router_id => '#{router2_ip}',
      networks4 => [
        '#{ipv4_network}',
        '#{additional_v4_network1}',
        '#{additional_v4_network2}',
        ],
      networks6 => [
        '#{ipv6_network}',
        '#{additional_v6_network1}',
        '#{additional_v6_network2}'
        ],
      peers => {
        #{router1_asn} => {
          'addr4'             => ['#{router1_ip}'],
          'addr6'             => ['#{router1_ip6}'],
          'desc'              => 'TEST Network',
          'default_originate' => true,
          }
      }
    }
    EOF
    it 'appling default acl' do
      apply_manifest(pp1, catch_failures: true)
      apply_manifest_on(router2, pp2, catch_failures: true)
    end
    it 'clean acl run on router1' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    it 'clean acl run on router2' do
      expect(apply_manifest_on(router2, pp2, catch_failures: true).exit_code).to eq 0
    end
    describe command("bgpctl show rib peer-as #{router2_asn}") do
      let(:pre_command) { 'sleep 120' }

      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network2}\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+0\.0\.0\.0/0\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network2}\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+::/0\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
    end
  end
  context 'defaultv4' do
    pp1 = <<-EOF
    class { '::routing':
      my_asn => #{router1_asn},
      fib_update => false,
      router_id => '#{router1_ip}',
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'v4default',
          }
      }
    }
    EOF
    it 'appling default acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    describe command("bgpctl show rib peer-as #{router2_asn}") do
      let(:pre_command) { 'sleep 120' }

      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network2}\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+0\.0\.0\.0/0\s+#{router2_ip}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network2}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b::/0\b}) }
    end
  end
  context 'defaultv6' do
    pp1 = <<-EOF
    class { '::routing':
      my_asn => #{router1_asn},
      fib_update => false,
      router_id => '#{router1_ip}',
      peers => {
        #{router2_asn} => {
          'addr4'          => ['#{router2_ip}'],
          'addr6'          => ['#{router2_ip6}'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'v6default',
          }
      }
    }
    EOF
    it 'appling default acl' do
      apply_manifest(pp1, catch_failures: true)
    end
    it 'clean acl run' do
      expect(apply_manifest(pp1, catch_failures: true).exit_code).to eq 0
    end
    describe command("bgpctl show rib peer-as #{router2_asn}") do
      let(:pre_command) { 'sleep 120' }

      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v4_network2}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b0\.0\.0\.0\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network1}\b}) }
      its(:stdout) { is_expected.not_to match(%r{\b#{additional_v6_network2}\b}) }
      its(:stdout) do
        is_expected.to match(
          %r{\*>\s+::/0\s+#{router2_ip6}\s+\d+\s+\d+\s+#{router2_asn}\s+i}
        )
      end
    end
  end
end
