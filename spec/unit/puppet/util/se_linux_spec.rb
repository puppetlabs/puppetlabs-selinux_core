require 'spec_helper'

require 'pathname'

require 'puppet/util/selinux'
include Puppet::Util::SELinux

unless defined?(Selinux)
  # Define the selinux module
  module Selinux
    def self.is_selinux_enabled
      false
    end
  end
end

describe Puppet::Util::SELinux do
  context 'selinux_support?' do
    it 'returns :true if this system has SELinux enabled' do
      allow(Selinux).to receive(:is_selinux_enabled).and_return 1
      expect(selinux_support?).to be_truthy
    end

    it 'returns :false if this system lacks SELinux' do
      allow(Selinux).to receive(:is_selinux_enabled).and_return 0
      expect(selinux_support?).to be_falsey
    end

    it 'returns nil if /proc/mounts does not exist' do
      allow(File).to receive(:open).with('/proc/mounts').and_raise('No such file or directory - /proc/mounts')
      expect(read_mounts).to eq(nil)
    end
  end

  context 'read_mounts' do
    before :each do
      fh = instance_double('fh', close: nil)
      allow(File).to receive(:open).with('/proc/mounts').and_return fh

      count = 0
      allow(fh).to receive(:read_nonblock) do
        raise EOFError if count >= 2
        count += 1
        <<-DOC
            rootfs / rootfs rw 0 0
            /dev/root / ext3 rw,relatime,errors=continue,user_xattr,acl,data=ordered 0 0
            /dev /dev tmpfs rw,relatime,mode=755 0 0
            /proc /proc proc rw,relatime 0 0
            /sys /sys sysfs rw,relatime 0 0
            192.168.1.1:/var/export /mnt/nfs nfs rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,nointr,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.1.1,mountvers=3,mountproto=udp,addr=192.168.1.1 0 0
        DOC
      end
    end

    it 'parses the contents of /proc/mounts' do
      expect(read_mounts).to eq(
        '/' => 'ext3',
        '/sys' => 'sysfs',
        '/mnt/nfs' => 'nfs',
        '/proc' => 'proc',
        '/dev' => 'tmpfs',
      )
    end
  end

  context 'filesystem detection' do
    before :each do
      allow(self).to receive(:read_mounts).and_return(
        '/' => 'ext3',
        '/sys' => 'sysfs',
        '/mnt/nfs' => 'nfs',
        '/proc' => 'proc',
        '/dev' => 'tmpfs',
      )
    end

    it 'matches a path on / to ext3' do
      expect(find_fs('/etc/puppetlabs/puppet/testfile')).to eq('ext3')
    end

    it 'matches a path on /mnt/nfs to nfs' do
      expect(find_fs('/mnt/nfs/testfile/foobar')).to eq('nfs')
    end

    it 'returns true for a capable filesystem' do
      expect(selinux_label_support?('/etc/puppetlabs/puppet/testfile')).to be_truthy
    end

    it 'returns false for a noncapable filesystem' do
      expect(selinux_label_support?('/mnt/nfs/testfile')).to be_falsey
    end

    it "(#8714) don't follow symlinks when determining file systems", unless: Puppet.features.microsoft_windows? do
      scratch = Pathname(PuppetSpec::Files.tmpdir('selinux'))

      allow(self).to receive(:read_mounts).and_return(
        '/' => 'ext3',
        scratch + 'nfs' => 'nfs',
      )

      (scratch + 'foo').make_symlink('nfs/bar')
      expect(selinux_label_support?(scratch + 'foo')).to be_truthy
    end

    it "handles files that don't exist" do
      scratch = Pathname(PuppetSpec::Files.tmpdir('selinux'))
      expect(selinux_label_support?(scratch + 'nonesuch')).to be_truthy
    end
  end

  context 'get_selinux_current_context' do
    it 'returns nil if no SELinux support' do
      allow(self).to receive(:selinux_support?).and_return false
      expect(get_selinux_current_context('/foo')).to be_nil
    end

    it 'returns a context' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lgetfilecon).with('/foo').and_return [0, 'user_u:role_r:type_t:s0']
      expect(get_selinux_current_context('/foo')).to eq('user_u:role_r:type_t:s0')
    end

    it 'returns nil if lgetfilecon fails' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lgetfilecon).with('/foo').and_return(-1)
      expect(get_selinux_current_context('/foo')).to be_nil
    end
  end

  context 'get_selinux_default_context' do
    it 'returns nil if no SELinux support' do
      allow(self).to receive(:selinux_support?).and_return false
      expect(get_selinux_default_context('/foo')).to be_nil
    end

    it 'returns a context if a default context exists' do
      allow(self).to receive(:selinux_support?).and_return true
      fstat = instance_double('File::Stat', mode: 0)
      allow(Puppet::FileSystem).to receive(:lstat).with('/foo').and_return(fstat)
      allow(self).to receive(:find_fs).with('/foo').and_return 'ext3'
      allow(Selinux).to receive(:matchpathcon).with('/foo', 0).and_return [0, 'user_u:role_r:type_t:s0']

      expect(get_selinux_default_context('/foo')).to eq('user_u:role_r:type_t:s0')
    end

    it 'handles permission denied errors by issuing a warning' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(self).to receive(:selinux_label_support?).and_return true
      allow(Selinux).to receive(:matchpathcon).with('/root/chuj', 0).and_return(-1)
      allow(self).to receive(:file_lstat).with('/root/chuj').and_raise(Errno::EACCES, '/root/chuj')

      expect(get_selinux_default_context('/root/chuj')).to be_nil
    end

    it 'handles no such file or directory errors by issuing a warning' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(self).to receive(:selinux_label_support?).and_return true
      allow(Selinux).to receive(:matchpathcon).with('/root/chuj', 0).and_return(-1)
      allow(self).to receive(:file_lstat).with('/root/chuj').and_raise(Errno::ENOENT, '/root/chuj')

      expect(get_selinux_default_context('/root/chuj')).to be_nil
    end

    it 'returns nil if matchpathcon returns failure' do
      allow(self).to receive(:selinux_support?).and_return true
      fstat = instance_double('File::Stat', mode: 0)
      allow(Puppet::FileSystem).to receive(:lstat).with('/foo').and_return(fstat)
      allow(self).to receive(:find_fs).with('/foo').and_return 'ext3'
      allow(Selinux).to receive(:matchpathcon).with('/foo', 0).and_return(-1)

      expect(get_selinux_default_context('/foo')).to be_nil
    end

    it 'returns nil if selinux_label_support returns false' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(self).to receive(:find_fs).with('/foo').and_return 'nfs'
      expect(get_selinux_default_context('/foo')).to be_nil
    end
  end

  context 'parse_selinux_context' do
    it 'returns nil if no context is passed' do
      expect(parse_selinux_context(:seluser, nil)).to be_nil
    end

    it "returns nil if the context is 'unlabeled'" do
      expect(parse_selinux_context(:seluser, 'unlabeled')).to be_nil
    end

    it 'returns the user type when called with :seluser' do
      expect(parse_selinux_context(:seluser, 'user_u:role_r:type_t:s0')).to eq('user_u')
      expect(parse_selinux_context(:seluser, 'user-withdash_u:role_r:type_t:s0')).to eq('user-withdash_u')
    end

    it 'returns the role type when called with :selrole' do
      expect(parse_selinux_context(:selrole, 'user_u:role_r:type_t:s0')).to eq('role_r')
      expect(parse_selinux_context(:selrole, 'user_u:role-withdash_r:type_t:s0')).to eq('role-withdash_r')
    end

    it 'returns the type type when called with :seltype' do
      expect(parse_selinux_context(:seltype, 'user_u:role_r:type_t:s0')).to eq('type_t')
      expect(parse_selinux_context(:seltype, 'user_u:role_r:type-withdash_t:s0')).to eq('type-withdash_t')
    end

    context 'with spaces in the components' do
      it 'raises when user contains a space' do
        expect { parse_selinux_context(:seluser, 'user with space_u:role_r:type_t:s0') }.to raise_error Puppet::Error
      end

      it 'raises when role contains a space' do
        expect { parse_selinux_context(:selrole, 'user_u:role with space_r:type_t:s0') }.to raise_error Puppet::Error
      end

      it 'raises when type contains a space' do
        expect { parse_selinux_context(:seltype, 'user_u:role_r:type with space_t:s0') }.to raise_error Puppet::Error
      end

      it 'returns the range when range contains a space' do
        expect(parse_selinux_context(:selrange, 'user_u:role_r:type_t:s0 s1')).to eq('s0 s1')
      end
    end

    it 'returns nil for :selrange when no range is returned' do
      expect(parse_selinux_context(:selrange, 'user_u:role_r:type_t')).to be_nil
    end

    it 'returns the range type when called with :selrange' do
      expect(parse_selinux_context(:selrange, 'user_u:role_r:type_t:s0')).to eq('s0')
      expect(parse_selinux_context(:selrange, 'user_u:role_r:type-withdash_t:s0')).to eq('s0')
    end

    context 'with a variety of SELinux range formats' do
      ['s0', 's0:c3', 's0:c3.c123', 's0:c3,c5,c8', 'TopSecret', 'TopSecret,Classified', 'Patient_Record'].each do |range|
        it "should parse range '#{range}'" do
          expect(parse_selinux_context(:selrange, "user_u:role_r:type_t:#{range}")).to eq(range)
        end
      end
    end
  end

  context 'set_selinux_context' do
    before :each do
      fh = instance_double('fh', close: nil)
      allow(File).to receive(:open).with('/proc/mounts').and_return fh

      count = 0
      allow(fh).to receive(:read_nonblock) do
        raise EOFError if count > 0
        count += 1

        <<-DOC
          rootfs / rootfs rw 0 0
          /dev/root / ext3 rw,relatime,errors=continue,user_xattr,acl,data=ordered 0 0
          /dev /dev tmpfs rw,relatime,mode=755 0 0
          /proc /proc proc rw,relatime 0 0
          /sys /sys sysfs rw,relatime 0 0
        DOC
      end
    end

    it 'returns nil if there is no SELinux support' do
      allow(self).to receive(:selinux_support?).and_return false
      expect(set_selinux_context('/foo', 'user_u:role_r:type_t:s0')).to be_nil
    end

    it 'returns nil if selinux_label_support returns false' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(self).to receive(:selinux_label_support?).with('/foo').and_return false
      expect(set_selinux_context('/foo', 'user_u:role_r:type_t:s0')).to be_nil
    end

    it 'uses lsetfilecon to set a context' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lsetfilecon).with('/foo', 'user_u:role_r:type_t:s0').and_return 0
      expect(set_selinux_context('/foo', 'user_u:role_r:type_t:s0')).to be_truthy
    end

    it 'uses lsetfilecon to set user_u user context' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lgetfilecon).with('/foo').and_return [0, 'foo:role_r:type_t:s0']
      allow(Selinux).to receive(:lsetfilecon).with('/foo', 'user_u:role_r:type_t:s0').and_return 0
      expect(set_selinux_context('/foo', 'user_u', :seluser)).to be_truthy
    end

    it 'uses lsetfilecon to set role_r role context' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lgetfilecon).with('/foo').and_return [0, 'user_u:foo:type_t:s0']
      allow(Selinux).to receive(:lsetfilecon).with('/foo', 'user_u:role_r:type_t:s0').and_return 0
      expect(set_selinux_context('/foo', 'role_r', :selrole)).to be_truthy
    end

    it 'uses lsetfilecon to set type_t type context' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lgetfilecon).with('/foo').and_return [0, 'user_u:role_r:foo:s0']
      allow(Selinux).to receive(:lsetfilecon).with('/foo', 'user_u:role_r:type_t:s0').and_return 0
      expect(set_selinux_context('/foo', 'type_t', :seltype)).to be_truthy
    end

    it 'uses lsetfilecon to set s0:c3,c5 range context' do
      allow(self).to receive(:selinux_support?).and_return true
      allow(Selinux).to receive(:lgetfilecon).with('/foo').and_return [0, 'user_u:role_r:type_t:s0']
      allow(Selinux).to receive(:lsetfilecon).with('/foo', 'user_u:role_r:type_t:s0:c3,c5').and_return 0
      expect(set_selinux_context('/foo', 's0:c3,c5', :selrange)).to be_truthy
    end
  end

  context 'set_selinux_default_context' do
    it 'returns nil if there is no SELinux support' do
      allow(self).to receive(:selinux_support?).and_return false
      expect(set_selinux_default_context('/foo')).to be_nil
    end

    it 'returns nil if no default context exists' do
      allow(self).to receive(:get_selinux_default_context).with('/foo').and_return nil
      expect(set_selinux_default_context('/foo')).to be_nil
    end

    it 'does nothing and return nil if the current context matches the default context' do
      allow(self).to receive(:get_selinux_current_context).with('/foo').and_return 'user_u:role_r:type_t'
      expect(set_selinux_default_context('/foo')).to be_nil
    end

    it 'sets and return the default context if current and default do not match' do
      allow(self).to receive(:get_selinux_default_context).with('/foo').and_return 'user_u:role_r:type_t'
      allow(self).to receive(:get_selinux_current_context).with('/foo').and_return 'olduser_u:role_r:type_t'
      allow(self).to receive(:set_selinux_context).with('/foo', 'user_u:role_r:type_t').and_return true
      expect(set_selinux_default_context('/foo')).to eq('user_u:role_r:type_t')
    end
  end
end
