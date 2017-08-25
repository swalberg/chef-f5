# f5-cookbook

A set of resources for managing F5 load balancers. Currently a WIP, but it will create VIPs and pools, and add nodes to pools

## Requirements

### Platforms

- RHEL/Fedora and derivatives
- Debian/Ubuntu and derivatives

### Chef

- Chef 12.7+

### Cookbooks

- none

## Attributes

- `node['f5']['gem_version']` - Sets the version of the gem that will be installed via the resource
- `node['f5']['enabled_status']` - Can take one of three values:

  |`enabled_status` value|meaning|
  |----------------------|-------|
  | `:manual`            | the default, the `f5_pool` resource does not touch the node's enabled status on load balancer, allowing it to be managed manually on the load balancer |
  | `:disabled`          | if a node does not exist or does exist but is enabled, the load balancer will be asked to disable the node |
  | `:enabled`           | if a node does not exist or does exist but is disabled, the load balancer will be asked to enable the node |

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
  address 'vipaddress'
  port 'vipport'
  protocol 'protocol' # TCP default
  pool 'mypool'
end
```

See the documentation for [LocalLB::LBMethod](https://devcentral.f5.com/wiki/iControl.LocalLB__LBMethod.ashx) and [protocol](https://devcentral.f5.com/wiki/iControl.Common__ProtocolType.ashx).

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

## Testing

Run `bundle exec rake test` to run the chefspec tests.

`bundle exec rake guard` starts a [`guard`](https://github.com/guard/guard) listener which watches files and auto-runs rspec to provide faster feedback

`bundle exec rake lint` will run rubocop

## License and Authors

Author:: Sean Walberg ([sean@ertw.com](mailto:sean@ertw.com))
