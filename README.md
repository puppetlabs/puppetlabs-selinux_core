
# selinux_core

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with selinux_core](#setup)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - User documentation](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a id="description"></a>
## Description

Manage SELinux context of files.

<a id="setup"></a>
## Setup

<a id="setup-requirements"></a>
### Setup Requirements

In order to use the selinux module, you must have `selinux` ruby bindings available on the system.

<a id="usage"></a>
## Usage

To set the SELinux context on a file, use the following code:
```
file { "/path/to/file":
  selinux_ignore_defaults => false,
  selrange => 's0',
  selrole => 'object_r',
  seltype => 'krb5_home_t',
  seluser => 'user_u',
}
```

To manage a SELinux policy module, use the following code:
```
selmodule { 'selmodule_policy':
  ensure => present,
  selmoduledir => '/usr/share/selinux/targeted',
}
```

To manage SELinux booleans, use the following code:
```
selboolean { 'collectd_tcp_network_connect':
  persistent => true,
  value => on,
}
```

<a id="reference"></a>
## Reference

Please see REFERENCE.md for the reference documentation, and [the selinux section of the file type](https://puppet.com/docs/puppet/latest/types/file.html#file-attribute-selinux_ignore_defaults).

This module is documented using Puppet Strings.

For a quick primer on how Strings works, please see [this blog post](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules) or the [README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md) for Puppet Strings.

To generate documentation locally, run the following code:
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
This command will create a browsable `\_index.html` file in the `doc` directory. The references available here are all generated from YARD-style comments embedded in the code base. When any development happens on this module, the impacted documentation should also be updated.

<a id="limitations"></a>
## Limitations

This module is only available on platforms that have selinux ruby bindings available.

<a id="development"></a>
## Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide](https://puppet.com/docs/puppet/latest/contributing.html).
