# Reference

## Resource types
* [`selboolean`](#selboolean): Manages SELinux booleans on systems with SELinux support.  The supported booleans are any of the ones found in `/selinux/booleans/`.
* [`selmodule`](#selmodule): Manages loading and unloading of SELinux policy modules on the system.  Requires SELinux support.  See man semodule(8) for more information o
## Resource types

### selboolean

Manages SELinux booleans on systems with SELinux support.  The supported booleans
are any of the ones found in `/selinux/booleans/`.


#### Properties

The following properties are available in the `selboolean` type.

##### `value`

Valid values: on, off

Whether the SELinux boolean should be enabled or disabled.

#### Parameters

The following parameters are available in the `selboolean` type.

##### `name`

namevar

The name of the SELinux boolean to be managed.

##### `persistent`

Valid values: `true`, `false`

If set true, SELinux booleans will be written to disk and persist across reboots.
The default is `false`.

Default value: `false`


### selmodule

Manages loading and unloading of SELinux policy modules
on the system.  Requires SELinux support.  See man semodule(8)
for more information on SELinux policy modules.

**Autorequires:** If Puppet is managing the file containing this SELinux
policy module (which is either explicitly specified in the `selmodulepath`
attribute or will be found at {`selmoduledir`}/{`name`}.pp), the selmodule
resource will autorequire that file.


#### Properties

The following properties are available in the `selmodule` type.

##### `ensure`

Valid values: present, absent

The basic property that the resource should be in.

Default value: present

##### `syncversion`

Valid values: `true`, `false`

If set to `true`, the policy will be reloaded if the
version found in the on-disk file differs from the loaded
version.  If set to `false` (the default) the only check
that will be made is if the policy is loaded at all or not.

#### Parameters

The following parameters are available in the `selmodule` type.

##### `name`

namevar

The name of the SELinux policy to be managed.  You should not
include the customary trailing .pp extension.

##### `selmoduledir`

The directory to look for the compiled pp module file in.
Currently defaults to `/usr/share/selinux/targeted`.  If the
`selmodulepath` attribute is not specified, Puppet will expect to find
the module in `<selmoduledir>/<name>.pp`, where `name` is the value of the
`name` parameter.

Default value: /usr/share/selinux/targeted

##### `selmodulepath`

The full path to the compiled .pp policy module.  You only need to use
this if the module file is not in the `selmoduledir` directory.


