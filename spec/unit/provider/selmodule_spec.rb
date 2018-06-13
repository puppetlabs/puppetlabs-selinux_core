# Note: This unit test depends on having a sample SELinux policy file
# in the same directory as this test called selmodule-example
# with version 1.5.0.  The provided selmodule-example is the first
# 256 bytes taken from /usr/share/selinux/targeted/nagios.pp on Fedora 9

require 'spec_helper'
require 'stringio'

describe Puppet::Type.type(:selmodule).provider(:semodule) do
  let(:resource) { instance_double('resource', name: 'foo') }
  let(:provider) { described_class.new(resource) }

  before :each do
    allow(resource).to receive(:[]).and_return 'foo'
  end

  context 'exists? method' do
    it 'finds a module if it is already loaded' do
      allow(provider).to receive(:command).with(:semodule).and_return '/usr/sbin/semodule'
      allow(provider).to receive(:execpipe).with('/usr/sbin/semodule --list').and_yield StringIO.new("bar\t1.2.3\nfoo\t4.4.4\nbang\t1.0.0\n")
      expect(provider.exists?).to eq(:true)
    end

    it 'returns nil if not loaded' do
      allow(provider).to receive(:command).with(:semodule).and_return '/usr/sbin/semodule'
      allow(provider).to receive(:execpipe).with('/usr/sbin/semodule --list').and_yield StringIO.new("bar\t1.2.3\nbang\t1.0.0\n")
      expect(provider.exists?).to be_nil
    end

    it 'returns nil if module with same suffix is loaded' do
      allow(provider).to receive(:command).with(:semodule).and_return '/usr/sbin/semodule'
      allow(provider).to receive(:execpipe).with('/usr/sbin/semodule --list').and_yield StringIO.new("bar\t1.2.3\nmyfoo\t1.0.0\n")
      expect(provider.exists?).to be_nil
    end

    it 'returns nil if no modules are loaded' do
      allow(provider).to receive(:command).with(:semodule).and_return '/usr/sbin/semodule'
      allow(provider).to receive(:execpipe).with('/usr/sbin/semodule --list').and_yield StringIO.new('')
      expect(provider.exists?).to be_nil
    end
  end

  context 'selmodversion_file' do
    it 'returns 1.5.0 for the example policy file' do
      allow(provider).to receive(:selmod_name_to_filename).and_return "#{File.dirname(__FILE__)}/selmodule-example"
      expect(provider.selmodversion_file).to eq('1.5.0')
    end
  end

  context 'syncversion' do
    it 'returns :true if loaded and file modules are in sync' do
      allow(provider).to receive(:selmodversion_loaded).and_return '1.5.0'
      allow(provider).to receive(:selmodversion_file).and_return '1.5.0'
      expect(provider.syncversion).to eq(:true)
    end

    it 'returns :false if loaded and file modules are not in sync' do
      allow(provider).to receive(:selmodversion_loaded).and_return '1.4.0'
      allow(provider).to receive(:selmodversion_file).and_return '1.5.0'
      expect(provider.syncversion).to eq(:false)
    end

    it 'returns before checking file version if no loaded policy' do
      allow(provider).to receive(:selmodversion_loaded).and_return nil
      expect(provider.syncversion).to eq(:false)
    end
  end

  context 'selmodversion_loaded' do
    it 'returns the version of a loaded module' do
      allow(provider).to receive(:command).with(:semodule).and_return '/usr/sbin/semodule'
      allow(provider).to receive(:execpipe).with('/usr/sbin/semodule --list').and_yield StringIO.new("bar\t1.2.3\nfoo\t4.4.4\nbang\t1.0.0\n")
      expect(provider.selmodversion_loaded).to eq('4.4.4')
    end

    it 'returns raise an exception when running selmodule raises an exception' do
      allow(provider).to receive(:command).with(:semodule).and_return '/usr/sbin/semodule'
      allow(provider).to receive(:execpipe).with('/usr/sbin/semodule --list').and_yield("this is\nan error").and_raise(Puppet::ExecutionFailure, 'it failed')
      expect { provider.selmodversion_loaded }.to raise_error(Puppet::ExecutionFailure, %r{Could not list policy modules: ".*" failed with "this is an error"})
    end
  end
end
