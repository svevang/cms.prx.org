require 'test_helper'

describe Fixerable do

  class FixerableTestModel
    include ActiveModel::Model
    include Fixerable
    fixerable_upload :the_temp_field, :the_final_field
    attr_accessor :the_temp_field
    attr_accessor :the_final_field
    def fixerable_final?
      false
    end
  end

  class FixerableTestUploader < CarrierWave::Uploader::Base
    storage :fog

    def self.version_formats
      {}
    end

    def authenticated_head_url
      'some-head-url'
    end
  end

  let(:uploader) { FixerableTestUploader.new }
  let(:model) do
    m = FixerableTestModel.new
    m.the_final_field = uploader
    m
  end

  it 'can get a provider for a url scheme' do
    FixerableTestModel.fixerable_storage['s3'].must_equal 'AWS'
  end

  it 'can get the storage provider for a uri' do
    FixerableTestModel.fixerable_storage_for_uri('google://g.com/p/f.mp3').must_equal 'Google'
  end

  it 'returns signed urls for aws uploads' do
    url = FixerableTestModel.fixerable_signed_url('s3://prx-development/another.mp3', uploader)
    url.must_match /another.mp3/
    url.must_match /X-Amz-Expires/
    url.must_match /X-Amz-Credential/
  end

  it 'signs HEAD requests for final aws uploads' do
    model.stub(:fixerable_final?, true) do
      model.asset_url(head: true).must_equal 'some-head-url'
    end
  end

  it 'can get the final storage url' do
    model.stub(:fixerable_final?, true) do
      model.fixerable_final_storage_url.must_equal "s3://#{ENV['AWS_BUCKET']}/"
    end

    model.the_temp_field = 'https://s3.aws.amazon.com/prx-development/another.mp3'
    model.fixerable_final_storage_url.must_equal nil
  end

  it 'signs HEAD requests for temp aws uploads' do
    fake_store = Fog::Storage::AWS.new(aws_access_key_id: 'foo', aws_secret_access_key: 'bar')
    Fog::Storage::AWS.stub(:new, fake_store) do
      fake_store.stub(:head_object_url, 'some-head-url') do
        model.the_temp_field = 's3://prx-development/another.mp3'
        model.asset_url(head: true).must_equal 'some-head-url'
      end
    end
  end

  it 'returns nil for plain urls' do
    url = FixerableTestModel.fixerable_signed_url('http://somewhere/something.mp3', uploader)
    url.must_be_nil
  end

  it 'determines url expiration from fog' do
    uploader.stub(:fog_authenticated_url_expiration, 400) do
      n = ::Fog::Time.now
      ::Fog::Time.stub(:now, n) do
        FixerableTestModel.fixerable_url_expires_at(uploader, {}).must_equal (n + 400)
      end
    end
  end

  it 'determines url expiration from options' do
    n = ::Fog::Time.now
    ::Fog::Time.stub(:now, n) do
      FixerableTestModel.fixerable_url_expires_at(uploader, expiration: 3600).must_equal (n + 3600)
    end
  end

  it 'can have an asset_url from a temp location' do
    model.the_temp_field = 'http://some/where/out/there'
    model.asset_url.must_equal 'http://some/where/out/there'
  end

  it 'can set expiration on asset_url from an upload' do
    model.the_temp_field = 's3://prx-development/another.mp3'
    one_day_url = model.asset_url(expiration: 3600)
    one_day_url.must_match /X-Amz-Expires=3600/
  end

  it 'can returned a signed url for a file' do
    signed_url = FixerableTestModel.fixerable_signed_url('s3://prx-development/another.mp3', uploader, expiration: 3600)
    signed_url.must_match /another.mp3/
    signed_url.must_match /X-Amz-Expires=3600/
  end

end
