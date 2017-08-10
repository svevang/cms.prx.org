require 'test_helper'

describe AudioVersionTemplate do

  let(:audio_version_template) { create(:audio_version_template) }
  let(:audio_version) { create(:audio_version, audio_version_template: audio_version_template) }

  it 'has a table defined' do
    AudioVersionTemplate.table_name.must_equal 'audio_version_templates'
  end

  it 'has a series' do
    audio_version_template.series.wont_be_nil
  end

  it 'can be created with valid attributes' do
    audio_version_template.must_be :valid?
  end

  it 'can tell if version doesnt have enough segments' do
    audio_version_template.segment_count = 2
    error_results = audio_version_template.validate_audio_version(audio_version)
    error_results.must_include 'has 1 audio files but must have 2'
  end

  it 'can tell if version length doesnt match template' do
    error_results = audio_version_template.validate_audio_version(audio_version)
    error_results.must_include 'long but must be 10 seconds - 1 minute and'
  end

  it 'validates with just a minimum' do
    audio_version_template.update(length_minimum: 120, length_maximum: 0)
    error_results = audio_version_template.validate_audio_version(audio_version)
    error_results.must_include 'long but must be more than 2 minutes'
  end

  it 'does not validate anything if all 0s' do
    audio_version_template.update(length_minimum: 0, length_maximum: 0)
    audio_version_template.validate_audio_version(audio_version).must_equal ''
  end

  it 'leaves a file alone if file complies with template' do
    audio_version_template.length_minimum = 0
    audio_version_template.validate_audio_version(audio_version).must_be(:empty?)
  end

  it 'checks template min against max' do
    audio_version_template.length_minimum = 20
    audio_version_template.length_maximum = 10
    audio_version_template.wont_be :valid?
  end

  it 'allows template max to be unset' do
    audio_version_template.length_minimum = 20
    audio_version_template.length_maximum = 0
    audio_version_template.must_be :valid?
  end

end
