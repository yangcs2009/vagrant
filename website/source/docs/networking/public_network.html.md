---
page_title: "Public Networks - Networking"
sidebar_current: "networking-public"
---

# Public Networks

**Network identifier: `public_network`**

Public networks are less private than private networks, and the exact
meaning actually varies from [provider to provider](/docs/providers),
hence the ambiguous definition. The idea is that while
[private networks](/docs/networking/private_network.html) should never allow the
general public access to your machine, public networks can.

-> **Confused?** We kind of are, too. It is likely that public networks will be
replaced by `:bridged` in a future release, since that is in general what should
be done with public networks, and providers that do not support bridging
generally do not have any other features that map to public networks either.

~> **Warning!** Vagrant boxes are insecure by default and by design, featuring
public passwords, insecure keypairs for SSH access, and potentially allow root
access over SSH. With these known credentials, your box is easily accessible by
anyone on your network. Before configuring Vagrant to use a public network,
consider _all_ potential security implications and review the
[default box configuration](/docs/boxes/base.html) to identify potential security
risks.

## DHCP

The easiest way to use a public network is to allow the IP to be assigned
via DHCP. In this case, defining a public network is trivially easy:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network"
end
```

When DHCP is used, the IP can be determined by using `vagrant ssh` to
SSH into the machine and using the appropriate command line tool to find
the IP, such as `ifconfig`.

## Static IP

Depending on your setup, you may wish to manually set the IP of your
bridged interface. To do so, add a `:ip` clause to the network definition.

```ruby
config.vm.network "public_network", ip: "192.168.0.17"
```

## Default Network Interface

If more than one network interface is available on the host machine, Vagrant will
ask you to choose which interface the virtual machine should bridge to. A default
interface can be specified by adding a `:bridge` clause to the network definition.

```ruby
config.vm.network "public_network", bridge: 'en1: Wi-Fi (AirPort)'
```

The string identifying the desired interface must exactly match the name of an
available interface. If it cannot be found, Vagrant will ask you to pick
from a list of available network interfaces.