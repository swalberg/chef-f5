# f5-cookbook

A LWRP to manage F5 VIPs and Pools. Currently a WIP. The documentation below may only refer to wishful thinking.

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
  <tr>
    <td><tt>['f5']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### f5::default

Not sure I'll use this.

Include `f5` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[f5::default]"
  ]
}
```

### LWRP

In an application's recipe,

```Ruby
f5_pool 'mypool' do
  host 'value'
  port 'value'
  lb_method 'method' # LB_METHOD_ROUND_ROBIN default
end

f5_vip 'myvip' do
  address 'vipaddress'
  port 'vipport'
  protocol 'protocol' # TCP default
  pool 'mypool'
end
```

See the documentation for [LocalLB::LBMethod](https://devcentral.f5.com/wiki/iControl.LocalLB__LBMethod.ashx) and [protocol](https://devcentral.f5.com/wiki/iControl.Common__ProtocolType.ashx).

## Testing

Run `bundle exec rspec` to run the chefspec tests.

## License and Authors

Author:: Sean Walberg (<sean@ertw.com>)
