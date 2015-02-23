# f5-cookbook

A LWRP to manage F5 VIPs and Pools. Currently a WIP, but it will create VIPs and pools, and add nodes to pools

## Supported Platforms

TBA

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
</table>

## Usage

### f5::default

Not needed at the moment

Include `f5` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[f5::default]"
  ]
}
```

Or if you are using a wrapper cookbook,

```
include_recipe "f5::default"
```

Your node will also need access to the credentials for the load balancer in the attributes:

```
default[:f5][:credentials][:default] = {
  host: "lb1.example.com",
  username: "chef-api",
  password: "TopSecret"
}
```
### LWRP

In an application's recipe:

```Ruby
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

Author:: Sean Walberg (<sean@ertw.com>)
