# encoding: utf-8

require 'test_helper'
require 'audio_file' if !defined?(AudioFile)

describe Api::AudioFileRepresenter do

  let(:audio_file)  { create(:audio_file) }
  let(:representer) { Api::AudioFileRepresenter.new(audio_file) }
  let(:json)        { JSON.parse(representer.to_json) }

  it 'create representer' do
    representer.wont_be_nil
  end

  it 'use representer to create json' do
    json['id'].must_equal audio_file.id
  end

  it 'serializes the length of the audio file as duration' do
    audio_file.stub(:duration, 123) do
      json['duration'].must_equal 123
    end
  end

  it 'links to the original' do
    json['_links']['original']['href'].must_match /#{audio_file.id}\/original/
  end

  it 'shows file validity' do
    json.keys.must_include('status')
  end

  it 'shows the analyzed audio format' do
    json['contentType'].must_equal 'audio/mpeg'
    json['layer'].must_equal 2
    json['frequency'].must_equal '44.1'
    json['bitRate'].must_equal 128
    json['channelMode'].must_equal 'Single Channel'
  end
end
