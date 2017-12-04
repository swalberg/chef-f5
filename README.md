# f5-cookbook

A set of resources for managing F5 load balancers. Currently a WIP, but it will create VIPs and pools, and add nodes to pools

## Requirements

### Platforms

- RHEL/Fedora and derivatives
- Debian/Ubuntu and derivatives
- Windows [2012.R2, 2016]

### Chef

- Chef 12.7+

### Cookbooks

- none

## Attributes

- `node['f5']['gem_version']` - Sets the version of the gem that will be installed via the resource
- `node['f5']['enabled_status']` - Can take one of three values:
  - `:manual` - the default, the `f5_pool` resource does not touch the node's enabled status on load balancer, allowing it to be managed manually on the load balancer
  - `:disabled` - if a node does not exist or does exist but is enabled, the load balancer will be asked to disable the node
  - `:enabled` - if a node does not exist or does exist but is disabled, the load balancer will be asked to enable the node

## Usage

Your node will also need access to the credentials for the load balancer either in the attributes or a data bag:

If you're using a data bag, call it `f5` and the default item is called `default`.

```
$ knife data bag show f5 default
Unencrypted data bag detected, ignoring any provided secret options.
host:     lb1.example.com
id:       default
password: TopSecret
username: chef-api
```

Or, if no data bag is found, attributes are used

```
default[:f5][:credentials][:default] = {
  host: "lb1.example.com",
  username: "chef-api",
  password: "TopSecret"
}
```

### Resources

In an application's recipe:

```ruby
# Creates the pool if missing and adds this node to the pool
# (currently using node.ipaddress and node.fqdn for the node)
f5_pool 'mypool' do
  host 'value'
  port 'value'
  lb_method 'method' # LB_METHOD_ROUND_ROBIN default
end

# Creates the VIP if missing
f5_vip 'myvip' do
  address 'vipaddress' # IPv4 or FQDN, see below
  port 'vipport'
  protocol 'protocol' # TCP default
  pool 'mypool'

  # this is optional; defaults to :manual so won't touch your setting
  #                   unless you specify one of the valid options.
  snat_pool :automap

  # this is optional; defaults to :manual so won't touch your setting
  #                   unless you specify one of the valid options.
  #                   :none disables the firewall_policy,
  #                   anything else is a named firewall_policy
  enforced_firewall_policy

  # this is optional; defaults to :manual so won't touch your setting
  #                   unless you specify one of the valid options.
  #                   :none disables the firewall_policy,
  #                   anything else is a named firewall_policy
  staged_firewall_policy
end
```

See the documentation for [LocalLB::LBMethod](https://devcentral.f5.com/wiki/iControl.LocalLB__LBMethod.ashx) and [protocol](https://devcentral.f5.com/wiki/iControl.Common__ProtocolType.ashx).

#### Using DNS for the name

This is an **experimental feature**. Some of the corner cases might not work :)

If you pass a FQDN to the VIP's address, this resource will attempt to resolve the name through DNS. If a match is found, the first address returned is used for the VIP. If no match is found, the resource will not be processed.


#### Manging node enabled status through node attributes

The `f5_pool` resource exposes an `enabled_status` property which allows you to explicitly take control of a node's enabled/disabled status within a pool via chef recipes and attributes.

```ruby
f5_pool 'mypool' do
  host 'value'
  port 'value'
  enabled_status :disabled
end
```

Though more commonly this is delegated to an attribute, which is the default behavior when this property is not specified explicitly:

```ruby
f5_pool 'mypool' do
  host 'value'
  port 'value'
end
```

is equivalent to

```ruby
f5_pool 'mypool' do
  host 'value'
  port 'value'
  enabled_status node['f5']['enabled_status']
end
```

and `node['f5']['enabled_status']` defaults to `:manual` so it won't touch the enabled status of your node in the pool unless you explicitly ask it to.

#### Managing virtual server client and server ssl profiles

The `f5_vip` resource exposes a pair or properties which allow you to add client and server SSL profiles to a virtual server.

```ruby
f5_vip 'myvip' do
  address 'vipaddress'
  port 'vipport'
  protocol 'protocol' # TCP default
  pool 'mypool'
  client_ssl_profile 'client.cert'
  server_ssl_profile 'server.cert'
end
```

These two properties are optional and only take effect if they are specified.

They will converge to ensure that profile is applied to the given vip, but there is currently no option to remove an SSL profile.

### Writing specs for vip and pool resources

This coobkook provides custom chefspec matchers so you can write specs like this:

```ruby
require 'chefspec'

describe 'example::default' do
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04').converge(described_recipe) }

  it 'creates the example_com pool (if needed) and adds this node to it' do
    expect(chef_run).to create_f5_pool('example_com').with(
      ip: '10.0.0.2',
      host: 'examplenode01.internaldomain.com',
      port: 80,
      monitor: 'test-monitor'
    )
  end

  it 'creates the example.com vip' do
    expect(chef_run).to create_f5_vip('example.com').with(
      address: '86.75.30.9',
      port: '80',
      protocol: 'PROTOCOL_TCP',
      pool: 'reallybasic'
    )
  end
end
```

NOTE: these matches verify only the presence (or absence via `expect(chef_run).to_not`) of a resource and the configuration of its properties according to hash passed to the optional `with` method.

The matchers cannot be used to validate whether convergence of an  `f5_pool` or `f5_vip` resource took place.

## Testing this cookbook

Run `bundle exec rake test` to run the chefspec tests.

`bundle exec rake guard` starts a [`guard`](https://github.com/guard/guard) listener which watches files and auto-runs rspec to provide faster feedback

`bundle exec rake lint` will run rubocop

## License and Authors

Author:: Sean Walberg ([sean@ertw.com](mailto:sean@ertw.com))
