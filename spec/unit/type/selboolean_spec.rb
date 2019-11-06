require 'spec_helper'

describe Puppet::Type.type(:selboolean) do
  context 'when validating attributes' do
    [:name, :persistent].each do |param|
      it "should have a #{param} parameter" do
        expect(Puppet::Type.type(:selboolean).attrtype(param)).to eq(:param)
      end
    end

    it 'has a value property' do
      expect(Puppet::Type.type(:selboolean).attrtype(:value)).to eq(:property)
    end
  end

  context 'when validating values' do
    before(:each) do
      klass = Puppet::Type.type(:selboolean)

      provider_class = instance_double('provider_class', name: 'fake', suitable?: true, supports_parameter?: true)
      allow(klass).to receive(:defaultprovider).and_return(provider_class)
      allow(klass).to receive(:provider).and_return(provider_class)

      provider = instance_double('provider', class: provider_class, clear: nil)
      allow(provider_class).to receive(:new).and_return(provider)
    end

    [:on, :off, :true, :false, true, false].each do |val|
      it "should support #{val.inspect} as a value to :value" do
        Puppet::Type.type(:selboolean).new(name: 'yay', value: val)
      end
    end

    it 'supports :true as a value to :persistent' do
      Puppet::Type.type(:selboolean).new(name: 'yay', value: :on, persistent: :true)
    end

    it 'supports :false as a value to :persistent' do
      Puppet::Type.type(:selboolean).new(name: 'yay', value: :on, persistent: :false)
    end
  end

  context 'when manipulating booleans' do
    let(:provider_class) { Puppet::Type::Selboolean.provider(Puppet::Type::Selboolean.providers[0]) }
    let(:bool) do
      Puppet::Type::Selboolean.new(
        name: 'foo',
        value: 'on',
        persistent: true,
      )
    end

    before :each do
      allow(Puppet::Type::Selboolean).to receive(:defaultprovider).and_return provider_class
    end

    it 'is able to access :name' do
      expect(bool[:name]).to eq('foo')
    end

    it 'is able to access :value' do
      expect(bool.property(:value).should).to eq(:on)
    end

    it 'sets :value to off' do
      bool[:value] = :off
      expect(bool.property(:value).should).to eq(:off)
    end

    it 'is able to access :persistent' do
      expect(bool[:persistent]).to eq(:true)
    end

    it 'sets :persistent to false' do
      bool[:persistent] = false
      expect(bool[:persistent]).to eq(:false)
    end
  end
end
