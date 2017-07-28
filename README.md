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

## Testing

Run `rspec` to run the chefspec tests.

## License and Authors

Author:: Sean Walberg ([sean@ertw.com](mailto:sean@ertw.com))
