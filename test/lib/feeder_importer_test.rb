require 'test_helper'
require 'feeder_importer'

describe FeederImporter do

  let(:account_id) { 8 }
  let(:user_id) { 8 }
  let(:podcast_id) { 40 }
  let(:importer) { FeederImporter.new(account_id, user_id, podcast_id) }

  it 'makes a new importer' do
    importer.wont_be_nil
  end

  it 'retrieves the feeder podcast' do
    remote_podcast = importer.retrieve_podcast
    remote_podcast.wont_be_nil
    remote_podcast.title.must_equal 'Transistor'
  end

  it 'creates a series' do
    importer.retrieve_podcast
    podcast = importer.podcast
    series = importer.create_series
    series.wont_be_nil
    series.title.must_equal 'Transistor'
    series.account_id.must_equal 8
    series.creator_id.must_equal 8
    series.short_description.must_match /^A podcast of scientific questions/
    series.description_html.must_match /^<p>Transistor is podcast of scientific curiosities/

    series.images.profile.wont_be_nil
    series.images.profile.upload.must_match /prx-up.s3.amazonaws.com\/test\/.+\/transistor1400.jpg/
    orig_re = /pub\/.+\/0\/web\/series_image\/\d+\/original\/transistor1400.jpg/
    podcast.itunes_images.first['original_url'].must_match orig_re

    series.images.thumbnail.wont_be_nil
    series.images.thumbnail.upload.must_match /prx-up.s3.amazonaws.com\/test\/.+\/transistor300.png/
    orig_re = /pub\/.+\/0\/web\/series_image\/\d+\/original\/transistor300.png/
    podcast.feed_images.first['original_url'].must_match orig_re

    series.audio_version_templates.size.must_equal 1
    series.audio_version_templates.first.audio_file_templates.size.must_equal 1

    series.distributions.size.must_equal 1
  end

  it 'creates a story from an episode' do
    importer.retrieve_podcast
    podcast = importer.podcast
    series = importer.create_series
    episode = podcast.episodes.first
    importer.create_story(episode)
  end
end
