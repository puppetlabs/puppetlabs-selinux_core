#! /usr/bin/env ruby
require 'spec_helper'

[:seluser, :selrole, :seltype, :selrange].each do |param|
  property = Puppet::Type.type(:file).attrclass(param)
  describe property do
    include PuppetSpec::Files

    before(:each) do
      @path = make_absolute('/my/file')
      @resource = Puppet::Type.type(:file).new path: @path
      @sel = property.new resource: @resource
      @sel.stubs(:normalize_selinux_category).with('s0').returns('s0')
      @sel.stubs(:normalize_selinux_category).with(nil).returns(nil)
    end

    it "retrieve on #{param} should return :absent if the file isn't statable" do
      @resource.expects(:stat).returns nil
      expect(@sel.retrieve).to eq(:absent)
    end

    it "should retrieve nil for #{param} if there is no SELinux support" do
      stat = stub 'stat', ftype: 'foo'
      @resource.expects(:stat).returns stat
      @sel.expects(:get_selinux_current_context).with(@path).returns nil
      expect(@sel.retrieve).to be_nil
    end

    it "should retrieve #{param} if a SELinux context is found with a range" do
      stat = stub 'stat', ftype: 'foo'
      @resource.expects(:stat).returns stat
      @sel.expects(:get_selinux_current_context).with(@path).returns 'user_u:role_r:type_t:s0'
      expectedresult = case param
                       when :seluser then 'user_u'
                       when :selrole then 'role_r'
                       when :seltype then 'type_t'
                       when :selrange then 's0'
      end
      expect(@sel.retrieve).to eq(expectedresult)
    end

    it "should retrieve #{param} if a SELinux context is found without a range" do
      stat = stub 'stat', ftype: 'foo'
      @resource.expects(:stat).returns stat
      @sel.expects(:get_selinux_current_context).with(@path).returns 'user_u:role_r:type_t'
      expectedresult = case param
                       when :seluser then 'user_u'
                       when :selrole then 'role_r'
                       when :seltype then 'type_t'
                       when :selrange then nil
      end
      expect(@sel.retrieve).to eq(expectedresult)
    end

    it 'handles no default gracefully' do
      @sel.expects(:get_selinux_default_context).with(@path).returns nil
      expect(@sel.default).to be_nil
    end

    it 'is able to detect matchpathcon defaults' do
      @sel.stubs(:debug)
      @sel.expects(:get_selinux_default_context).with(@path).returns 'user_u:role_r:type_t:s0'
      expectedresult = case param
                       when :seluser then 'user_u'
                       when :selrole then 'role_r'
                       when :seltype then 'type_t'
                       when :selrange then 's0'
      end
      expect(@sel.default).to eq(expectedresult)
    end

    it 'returns nil for defaults if selinux_ignore_defaults is true' do
      @resource[:selinux_ignore_defaults] = :true
      expect(@sel.default).to be_nil
    end

    it 'is able to set a new context' do
      @sel.should = ['newone']
      @sel.expects(:set_selinux_context).with(@path, ['newone'], param)
      @sel.sync
    end

    it 'does nothing for safe_insync? if no SELinux support' do
      @sel.should = %(newcontext)
      @sel.expects(:selinux_support?).returns false
      expect(@sel.safe_insync?('oldcontext')).to eq(true)
    end
  end
end
