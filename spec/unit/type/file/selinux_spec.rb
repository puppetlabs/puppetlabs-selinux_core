require 'spec_helper'

[:seluser, :selrole, :seltype, :selrange].each do |param|
  property = Puppet::Type.type(:file).attrclass(param)
  describe property do
    include PuppetSpec::Files

    let(:path) { make_absolute('/my/file') }
    let(:resource) { Puppet::Type.type(:file).new path: path }
    let(:sel) { property.new resource: resource }

    before(:each) do
      allow(sel).to receive(:normalize_selinux_category).with('s0').and_return('s0')
      allow(sel).to receive(:normalize_selinux_category).with(nil).and_return(nil)
    end

    it "retrieve on #{param} should return :absent if the file isn't statable" do
      expect(resource.stat).to be_nil
      expect(sel.retrieve).to eq(:absent)
    end

    it "should retrieve nil for #{param} if there is no SELinux support" do
      allow(resource).to receive(:stat).and_return('foo')
      expect(sel).to receive(:get_selinux_current_context).with(path).and_return nil
      expect(sel.retrieve).to be_nil
    end

    it "should retrieve #{param} if a SELinux context is found with a range" do
      allow(resource).to receive(:stat).and_return('foo')
      expect(sel).to receive(:get_selinux_current_context).with(path).and_return 'user_u:role_r:type_t:s0'
      expectedresult = case param
                       when :seluser then 'user_u'
                       when :selrole then 'role_r'
                       when :seltype then 'type_t'
                       when :selrange then 's0'
                       end
      expect(sel.retrieve).to eq(expectedresult)
    end

    it "should retrieve #{param} if a SELinux context is found without a range" do
      allow(resource).to receive(:stat).and_return('foo')
      expect(sel).to receive(:get_selinux_current_context).with(path).and_return 'user_u:role_r:type_t'
      expectedresult = case param
                       when :seluser then 'user_u'
                       when :selrole then 'role_r'
                       when :seltype then 'type_t'
                       when :selrange then nil
                       end
      expect(sel.retrieve).to eq(expectedresult)
    end

    it 'handles no default gracefully' do
      expect(sel).to receive(:get_selinux_default_context).with(path).and_return nil
      expect(sel.default).to be_nil
    end

    it 'is able to detect matchpathcon defaults' do
      allow(sel).to receive(:debug)
      expect(sel).to receive(:get_selinux_default_context).with(path).and_return 'user_u:role_r:type_t:s0'
      expectedresult = case param
                       when :seluser then 'user_u'
                       when :selrole then 'role_r'
                       when :seltype then 'type_t'
                       when :selrange then 's0'
                       end
      expect(sel.default).to eq(expectedresult)
    end

    it 'returns nil for defaults if selinux_ignore_defaults is true' do
      resource[:selinux_ignore_defaults] = :true
      expect(sel.default).to be_nil
    end

    it 'is able to set a new context' do
      sel.should = ['newone']
      expect(sel).to receive(:set_selinux_context).with(path, ['newone'], param)
      sel.sync
    end

    it 'does nothing for safe_insync? if no SELinux support' do
      sel.should = %(newcontext)
      expect(sel).to receive(:selinux_support?).and_return false
      expect(sel.safe_insync?('oldcontext')).to eq(true)
    end
  end
end
