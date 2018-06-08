require 'spec_helper'

describe Puppet::Type.type(:selmodule) do
  context 'when validating attributes' do
    [:name, :selmoduledir, :selmodulepath].each do |param|
      it "should have a #{param} parameter" do
        expect(Puppet::Type.type(:selmodule).attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :syncversion].each do |param|
      it "should have a #{param} property" do
        expect(Puppet::Type.type(:selmodule).attrtype(param)).to eq(:property)
      end
    end
  end

  context 'when checking policy modules' do
    let(:provider_class) { Puppet::Type::Selmodule.provider(Puppet::Type::Selmodule.providers[0]) }
    let(:selmodule) do
      Puppet::Type::Selmodule.new(
        name: 'foo',
        selmoduledir: '/some/path',
        selmodulepath: '/some/path/foo.pp',
        syncversion: true,
      )
    end

    before :each do
      allow(Puppet::Type::Selmodule).to receive(:defaultprovider).and_return provider_class
    end

    it 'is able to access :name' do
      expect(selmodule[:name]).to eq('foo')
    end

    it 'is able to access :selmoduledir' do
      expect(selmodule[:selmoduledir]).to eq('/some/path')
    end

    it 'is able to access :selmodulepath' do
      expect(selmodule[:selmodulepath]).to eq('/some/path/foo.pp')
    end

    it 'is able to access :syncversion' do
      expect(selmodule[:syncversion]).to eq(:true)
    end

    it 'sets the syncversion value to false' do
      selmodule[:syncversion] = :false
      expect(selmodule[:syncversion]).to eq(:false)
    end
  end
end
