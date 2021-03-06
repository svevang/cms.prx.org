require 'test_helper'
require 'public_asset'

class BasePublicAsset
  include PublicAsset
end

class MockFile
  def url(version = 'original')
    version
  end
end

class TestPublicAsset
  include PublicAsset

  attr_accessor :name
  def initialize(n); @name = n; end
  def id; 1; end
  def public_asset_filename; name; end
  def token_secret; 'secret'; end

  def file
    MockFile.new
  end
end

describe PublicAsset do

  let(:public_asset) { TestPublicAsset.new('test.mp3') }
  let(:bare_public_asset) { BasePublicAsset.new }

  it 'generates a token using defaults' do
    defaults = public_asset.set_asset_option_defaults
    public_asset.public_url_token(defaults).must_equal "5033d06991dc5b69e38275253bfb3b24"
  end

  it 'generates a public url' do
    public_asset.public_url.must_match /http(.+)cms(.+)prx(.+)\/pub\/5033d06991dc5b69e38275253bfb3b24\/0\/web\/test_public_asset\/1\/original\/test\.mp3/
  end

  it 'generates an asset url' do
    public_asset.asset_url.must_equal 'original'
  end

  it 'sets default options' do
    defaults = public_asset.set_asset_option_defaults
    defaults[:use].must_equal 'web'
    defaults[:class].must_equal 'test_public_asset'
    defaults[:id].must_equal 1
    defaults[:version].must_equal 'original'
    defaults[:name].must_equal 'test'
    defaults[:extension].must_equal 'mp3'
    defaults[:expires].must_equal 0
  end

  it 'has a token secret' do
    bare_public_asset.token_secret.wont_be_nil
  end

  it 'tests if valid' do
    public_asset.public_url_valid?({}).must_equal false

    options = public_asset.set_asset_option_defaults
    options[:token] = public_asset.public_url_token(options)
    public_asset.public_url_valid?(options).must_equal true
  end

  it 'tests if expired' do
    public_asset.url_expired?({expires: 1.week.ago.to_i}).must_equal true
  end
end
