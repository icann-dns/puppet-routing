# frozen_string_literal: true

require 'spec_helper'

describe 'routing' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'routing.example.com' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      my_asn: 64496,
      router_id: '192.0.2.2',
      # :daemon => "$::routing::params::daemon",
      networks4: ['192.0.2.0/25'],
      networks6: ['2001:DB8::/48'],
      failsafe_networks4: ['192.0.2.0/24'],
      failsafe_networks6: ['2001:DB8::/32'],
      # :failover_server => false,
      # :enable_advertisements => true,
      # :enable_advertisements_v4 => true,
      # :enable_advertisements_v6 => true,
      # :peers => {},
      # :enable_nagios => false

    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(zone_status_errors: false)
      end

      case facts[:kernel]
      when 'FreeBSD'
        let(:routing_class) { 'openbgpd' }
      else
        let(:routing_class) { 'quagga::bgpd' }
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('routing::params') }

        
  it do
    is_expected.to contain_class(routing_class)
        .with({
          "my_asn" => 64496,
          "router_id" => '192.0.2.2',
          "networks4" => ['192.0.2.0/25'],
          "networks6" => ['2001:DB8::/48'],
          "failsafe_networks4" => ['192.0.2.0/24'],
          "failsafe_networks6" => ['2001:DB8::/32'],
          "failover_server" => false,
          "enable_advertisements" => true,
          "enable_advertisements_v4" => true,
          "enable_advertisements_v6" => true,
          "peers" => {},
          })
  end
  
      end
      describe 'Change Defaults' do
        context 'my_asn' do
          before { params.merge!( my_asn: 64497 ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "my_asn" => 64497 })}
        end
        context 'router_id' do
          before { params.merge!( router_id: '192.0.2.3' ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "router_id" => '192.0.2.3' })}
        end
        context 'networks4' do
          before { params.merge!( networks4: ['192.0.2.0/23'] ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "networks4" => ['192.0.2.0/23'] })}
        end
        context 'networks6' do
          before { params.merge!( networks6: ['2001:DB8::/47'] ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "networks6" => ['2001:DB8::/47'] })}
        end
        context 'failsafe_networks4' do
          before { params.merge!( failsafe_networks4: ['192.0.2.0/23'] ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "failsafe_networks4" => ['192.0.2.0/23'] })}
        end
        context 'failsafe_networks6' do
          before { params.merge!( failsafe_networks6: ['2001:DB8::/47'] ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "failsafe_networks6" => ['2001:DB8::/47'] })}
        end
        context 'failover_server' do
          before { params.merge!( failover_server: true ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "failover_server" => true })}
        end
        context 'failover_server' do
          let(:facts) {facts.merge({ "zone_status_errors" => true })}
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "failover_server" => true })}
        end
        context 'enable_advertisements' do
          before { params.merge!( enable_advertisements: false ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "enable_advertisements" => false })}
        end
        context 'enable_advertisements_v4' do
          before { params.merge!( enable_advertisements_v4: false ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "enable_advertisements_v4" => false })}
        end
        context 'enable_advertisements_v6' do
          before { params.merge!( enable_advertisements_v6: false ) }
          it { is_expected.to compile }
          it { is_expected.to contain_class(routing_class).with({
            "enable_advertisements_v6" => false })}
        end
        context 'enable_nagios' do
          before { params.merge!( enable_nagios: true ) }
          it { is_expected.to compile }
        end
      end
      describe 'check bad type' do
        context 'my_asn' do
          before { params.merge!( my_asn: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'router_id' do
          before { params.merge!( outer_id: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'daemon' do
          before { params.merge!( daemon: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'networks4' do
          before { params.merge!( networks4: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'networks6' do
          before { params.merge!( networks6: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'failsafe_networks4' do
          before { params.merge!( failsafe_networks4: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'failsafe_networks6' do
          before { params.merge!( failsafe_networks6: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'failover_server' do
          before { params.merge!( failover_server: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_advertisements' do
          before { params.merge!( enable_advertisements: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_advertisements_v4' do
          before { params.merge!( enable_advertisements_v4: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_advertisements_v6' do
          before { params.merge!( enable_advertisements_v6: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers' do
          before { params.merge!( peers: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
