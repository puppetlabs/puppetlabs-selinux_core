require 'spec_helper'

provider_class = Puppet::Type.type(:selboolean).provider(:getsetsebool)

describe provider_class do
  let(:resource) { instance_double('resource', name: 'foo') }
  let(:provider) { provider_class.new(resource) }

  before :each do
    allow(resource).to receive(:[]).and_return 'foo'
  end

  it 'returns :on when getsebool returns on' do
    allow(provider).to receive(:getsebool).with('foo').and_return "foo --> on\n"
    expect(provider.value).to eq(:on)
  end

  it 'returns :off when getsebool returns on' do
    allow(provider).to receive(:getsebool).with('foo').and_return "foo --> off\n"
    expect(provider.value).to eq(:off)
  end

  it 'calls execpipe when updating boolean setting' do
    allow(provider).to receive(:command).with(:setsebool).and_return '/usr/sbin/setsebool'
    allow(provider).to receive(:execpipe).with('/usr/sbin/setsebool  foo off')
    provider.value = :off
  end

  it 'calls execpipe with -P when updating persistent boolean setting' do
    allow(resource).to receive(:[]).with(:persistent).and_return :true
    allow(provider).to receive(:command).with(:setsebool).and_return '/usr/sbin/setsebool'
    allow(provider).to receive(:execpipe).with('/usr/sbin/setsebool -P foo off')
    provider.value = :off
  end
end
