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
      my_asn: 64_496,
      router_id: '192.0.2.2',
      networks4: ['192.0.2.0/25'],
      networks6: ['2001:DB8::/48'],
      failsafe_networks4: ['192.0.2.0/24'],
      failsafe_networks6: ['2001:DB8::/32'],
      #:failover_server => false,
      #:enable_advertisements => true,
      #:enable_advertisements_v4 => true,
      #:enable_advertisements_v6 => true,
      #:conf_file => '/usr/local/etc/bgpd.conf',
      #:package => 'routing',
      #:service => 'routing',
      #:enable => true,
      peers: {
        64_497 => {
          'addr4'          => ['192.0.2.2'],
          'addr6'          => ['2001:DB8::2'],
          'desc'           => 'TEST Network',
          'inbound_routes' => 'all',
          'communities'    => ['no-export', '64_497:100'],
          'multihop'       => 5,
          'prepend'        => 3
        },
        64_498 => {
          'addr4'          => ['192.0.2.3'],
          'desc'           => 'TEST 2 Network'
        }
      }
    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(zone_status_errors: false) }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
      end
      describe 'Change Defaults' do
        context 'networks4' do
          before { params.merge!(networks4: []) }
          it { is_expected.to compile }
        end
        context 'networks6' do
          before { params.merge!(networks6: []) }
          it { is_expected.to compile }
        end
        context 'failsafe_networks4' do
          before { params.merge!(failsafe_networks4: []) }
          it { is_expected.to compile }
        end
        context 'failsafe_networks6' do
          before { params.merge!(failsafe_networks6: []) }
          it { is_expected.to compile }
        end
        context 'failover_server' do
          before { params.merge!(failover_server: true) }
          it { is_expected.to compile }
        end
        context 'enable_advertisements' do
          before { params.merge!(enable_advertisements: false) }
          it { is_expected.to compile }
        end
        context 'enable_advertisements_v4' do
          before { params.merge!(enable_advertisements_v4: false) }
          it { is_expected.to compile }
        end
        context 'enable_advertisements_v6' do
          before { params.merge!(enable_advertisements_v6: false) }
          it { is_expected.to compile }
        end
        context 'peer addr4' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.3'],
                  'addr6'          => ['2001:DB8::2'],
                  'desc'           => 'TEST Network',
                  'inbound_routes' => 'all',
                  'communities'    => ['no-export', '64_497:100'],
                  'multihop'       => 5,
                  'prepend'        => 3
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'peer addr6' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.2'],
                  'addr6'          => ['2001:DB8::3'],
                  'desc'           => 'TEST Network',
                  'inbound_routes' => 'all',
                  'communities'    => ['no-export', '64_497:100'],
                  'multihop'       => 5,
                  'prepend'        => 3
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'peer desc' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.2'],
                  'addr6'          => ['2001:DB8::2'],
                  'desc'           => 'FOO Network',
                  'inbound_routes' => 'all',
                  'communities'    => ['no-export', '64_497:100'],
                  'multihop'       => 5,
                  'prepend'        => 3
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'peer multihop' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.2'],
                  'addr6'          => ['2001:DB8::2'],
                  'desc'           => 'TEST Network',
                  'inbound_routes' => 'all',
                  'communities'    => ['no-export', '64_497:100'],
                  'multihop'       => 1,
                  'prepend'        => 3
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'peer prepend' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.2'],
                  'addr6'          => ['2001:DB8::2'],
                  'desc'           => 'TEST Network',
                  'inbound_routes' => 'all',
                  'communities'    => ['no-export', '64_497:100'],
                  'multihop'       => 5,
                  'prepend'        => 2
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'peer inbound-routes default' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.2'],
                  'addr6'          => ['2001:DB8::2'],
                  'desc'           => 'TEST Network',
                  'inbound_routes' => 'default',
                  'communities'    => ['no-export', '64_497:100'],
                  'multihop'       => 5,
                  'prepend'        => 3
                }
              }
            )
          end
          it { is_expected.to compile }
        end
        context 'peer communities' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'addr4'          => ['192.0.2.2'],
                  'addr6'          => ['2001:DB8::2'],
                  'desc'           => 'TEST Network',
                  'inbound_routes' => 'all',
                  'communities'    => ['no-export', '64_497:200'],
                  'multihop'       => 5,
                  'prepend'        => 3
                }
              }
            )
          end
          it { is_expected.to compile }
        end
      end
      describe 'check bad type' do
        context 'peers string as key' do
          before { params.merge!(peers: { '64_497' => { 'desc' => 'foo' } }) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers missing desc' do
          before { params.merge!(peers: { 64_497 => {} }) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers unknown key' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'foo' => 'bar'
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad addr4 not array' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'addr4' => '192.0.2.2'
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad addr4 not valid ip' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'addr4' => ['192.0.2.2.1']
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad addr6 not array' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'addr6' => '2001:DB8::2'
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad addr6 not valid ip' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'addr6' => ['12001:DB8::2']
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad desc' do
          before { params.merge!(peers: { 64_497 => { 'desc' => true } }) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad communities' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'communities' => 'no-export'
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad communities' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'communities' => ['foobar']
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad multihop type' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'multihop' => true
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad multihop to big' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'multihop' => 256
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad prepend bad type' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'prepend' => true
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad prepend tp big' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'prepend' => 256
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'peers bad inbound_routes' do
          before do
            params.merge!(
              peers: {
                64_497 => {
                  'desc' => 'foo',
                  'inbound_routes' => 'foo'
                }
              }
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
