require 'test_helper'

describe Story do
  let(:story) { create(:story, audio_versions_count: 10) }
  let(:promos_only) { create(:story_promos_only) }

  describe 'basics' do
    it 'has a table defined' do
      Story.table_name.must_equal 'pieces'
    end

    it 'has points' do
      story.points.must_equal 10
    end

    it 'has purchases' do
      story.must_respond_to :purchases
    end

    it 'is v4 by default' do
      create(:story).must_be :v4?
    end

    it 'is deleted by default' do
      create(:story).must_be :deleted?
    end
  end

  describe 'status updates' do
    let(:story) { create(:story) }

    it 'changes to valid when audio file updated' do
      av = story.audio_versions(true).first
      af = av.audio_files(true).first

      story.update_column(:status, 'invalid')
      av.update_column(:status, 'invalid')
      af.update_column(:status, 'mp3s created')

      af.save!
      af.run_callbacks(:commit)
      av.run_callbacks(:commit)

      [af, av, story].each { |m| m.reload.status.must_equal 'complete' }
    end

    it 'changes to valid when invalid audio file destroyed' do
      av = story.audio_versions(true).first
      af = av.audio_files(true).first
      af.run_callbacks(:commit)
      av.run_callbacks(:commit)
      [af, av, story].each { |m| m.reload.status.must_equal 'complete' }

      af.update_columns(status: 'invalid', status_message: 'bad')
      af.run_callbacks(:commit)
      av.run_callbacks(:commit)
      [af, av, story].each { |m| m.reload.status.must_equal 'invalid' }

      af.destroy
      av.run_callbacks(:commit)
      [av, story].each { |m| m.reload.status.must_equal 'complete' }
    end
  end

  describe 'checking audio versions' do
    let(:story) { create(:story) }
    let(:invalid_audio_versions) { create_list(:audio_version_with_template, 5) }
    let(:valid_audio_versions) { create_list(:audio_version, 5) }

    it 'is invalid if it has no audio' do
      story.audio_versions = []
      story.update(title: 'test title')
      story.status.must_equal 'invalid'
      story.status_message.must_include 'has no audio.'
    end

    it 'is invalid if any its audio versions are invalid' do
      story.audio_versions = invalid_audio_versions
      story.update(title: 'Title!')
      story.status.must_equal 'invalid'
      story.status_message.must_include 'Invalid audio version: '
    end

    it 'is valid if all its audio versions are valid' do
      story.audio_versions = valid_audio_versions
      story.update(title: 'Title!')
      story.status.must_equal 'complete'
      story.status_message.must_be_nil
    end
  end

  describe 'distributions' do
    let(:series) { create(:series) }
    let(:story) { create(:story, series: series) }

    it 'creates story distributions' do
      stub_request(:post, 'https://id.prx.org/token').
        to_return(status: 200,
                  body: '{"access_token":"abc123","token_type":"bearer"}',
                  headers: { 'Content-Type' => 'application/json; charset=utf-8' })

      stub_request(:get, 'https://feeder.prx.org/api/v1/podcasts/23').
        to_return(status: 200, body: json_file(:podcast), headers: {})

      stub_request(:post, 'https://feeder.prx.org/api/v1/podcasts/23/episodes').
        to_return(status: 200, body: json_file(:episode), headers: {})

      series.distributions.count.must_equal 1
      story.distributions(true).count.must_equal 0
      story.create_story_distributions
      story.distributions(true).count.must_equal 1
    end
  end

  describe 'using default audio version' do
    it 'finds default audio' do
      story.audio_versions.count.must_equal 10
      story.default_audio_version.audio_files.count.must_be :>=, 1
      story.default_audio.wont_be_nil
    end

    it 'has a content advisory from the default audio version' do
      story.content_advisory.must_equal story.default_audio_version.content_advisory
    end

    it 'produces a nil content advisory for no default audio version' do
      story.stub(:default_audio_version, nil) do
        story.content_advisory.must_be_nil
      end
    end

    it 'has timing and cues from the default audio version' do
      story.timing_and_cues.must_equal story.default_audio_version.timing_and_cues
    end

    it 'produces a nil timing and cues for no default audio version' do
      story.stub(:default_audio_version, nil) do
        story.timing_and_cues.must_be_nil
      end
    end

    it 'has empty default audio with no default_audio_version' do
      story.stub(:default_audio_version, nil) do
        story.default_audio.must_equal []
      end
    end

    it 'returns 0 for duration when there is no default audio version' do
      story.stub(:default_audio_version, nil) do
        story.duration.must_equal 0
      end
    end

    it 'has a transcript from the default audio version' do
      story.transcript.must_equal story.default_audio_version.transcript
    end
  end

  describe '#default_image' do
    it 'returns the first image when one is present' do
      story.stub(:images, [:image, :second_image]) do
        story.default_image.must_equal :image
      end
    end

    it 'returns nil when no image is present' do
      story.stub(:images, []) do
        story.default_image.must_equal nil
      end
    end
  end

  describe '#tags' do
    it 'has topics' do
      story.must_respond_to(:topics)
    end

    it 'has tones' do
      story.must_respond_to(:tones)
    end

    it 'has formats' do
      story.must_respond_to(:formats)
    end

    it 'can have user tags' do
      story.must_respond_to(:user_tags)
    end

    it 'can set tags as a list' do
      story.tags = ['a', 'b', 'b']
      story.user_tags.count.must_equal 2
      story.user_tags.map(&:to_tag).sort.must_equal ['a', 'b']
      story.tags = nil
      story.user_tags.count.must_equal 0
    end

    it 'returns tones, topics, formats, and user tags with #tags' do
      topic = create(:topic, story: story, name: 'Asian')
      tones = create(:tone, story: story, name: 'Amusing')
      format = build(:format, story: story, name: 'Fundraising for Air')
      format.save(validate: false)
      user_tag = create(:user_tag, name: 'user_tag')
      tagging = create(:tagging, taggable: story, user_tag: user_tag)

      story.tags.must_include 'Asian'
      story.tags.must_include 'Amusing'
      story.tags.must_include 'Fundraising'
      story.tags.must_include 'user_tag'
    end
  end

  describe '#subscription_episode?' do
    let(:series) { build_stubbed(:series) }

    before :each do
      story.series = series
    end

    it 'returns true if series is subscribable' do
      story.must_be :subscription_episode?
    end

    it 'returns false otherwise' do
      series.subscription_approval_status = Series::SUBSCRIPTION_NEW

      story.wont_be :subscription_episode?
    end

    describe '#episode_date' do
      it 'returns the episode date' do
        story.episode_number = 3
        create(:schedule, series: series)

        story.episode_date.must_equal series.get_datetime_for_episode_number(3)
      end
    end
  end

  describe 'publishing' do
    let(:story) { create(:story) }

    it 'publishes a story' do
      story.published_at = nil
      story.released_at = nil
      story.publish!
      story.published_at.wont_be_nil
    end

    it 'publishes a story with a release date' do
      release_date = 1.week.ago
      story.published_at = nil
      story.released_at = release_date
      story.publish!
      story.published_at.must_equal release_date
    end

    it 'removes future publish date when release date is removed' do
      story.update_attributes(published_at: 1.week.from_now, released_at: 1.week.from_now)
      story.published_at.wont_be_nil
      story.update_attributes(released_at: nil)
      story.published_at.must_be_nil
    end

    it 'orders coalesce publish and release dates' do
      now = Time.now
      title = 'coalesced story'
      create(:unpublished_story, title: title, short_description: '0')
      create(:unpublished_story, title: title, short_description: '1', released_at: now)
      create(:story, title: title, short_description: '2', published_at: now - 1)
      create(:unpublished_story, title: title, short_description: '3', released_at: now + 1)

      stories = Story.where(title: title).coalesce_published_released('desc').all.to_a
      stories.map(&:short_description).must_equal ['0', '3', '1', '2']
    end

    it 'wont publish when already published' do
      lambda do
        story.publish!
        story.publish!
      end.must_raise(RuntimeError)
    end

    it 'unpublishes a story' do
      story.published_at = Time.now
      story.unpublish!
      story.published_at.must_be_nil
    end

    it 'unpublishes a story with a release date' do
      story.released_at = Time.now
      story.published_at = story.released_at
      story.unpublish!
      story.published_at.must_be_nil
      story.released_at.wont_be_nil
    end

    it 'wont unpublish an unpublished story' do
      lambda do
        story.unpublish!
        story.unpublish!
      end.must_raise(RuntimeError)
    end

    it 'allows the published date to be set via boolean' do
      [false, 'f', 'false', '0', 0].each do |v|
        story.published = v
        story.published_at.must_be_nil
        story.wont_be :published?
      end

      [true, 't', 'true', '1', 1].each do |v|
        story.published = v
        story.published_at.wont_be_nil
        story.must_be :published?
      end
    end
  end

  describe 'deleting' do
    let(:story) { create(:story) }
    let(:story_v3) { create(:story_v3) }

    it 'actually deletes v4 stories' do
      story.destroy!
      Story.unscoped.where(id: story.id).count.must_equal 0
    end

    it 'soft deletes v3 stories' do
      story_v3.destroy!
      Story.unscoped.where(id: story_v3.id).count.must_equal 1
    end
  end

  describe 'scopes' do
    it 'wont include network_only stories' do
      story = create(:story, network_only_at: Time.now)
      Story.where(id: story.id).must_include story
      Story.where(id: story.id).network_visible.wont_include story
    end

    it 'wont include subscriber_only stories' do
      series = create(:series,
                      subscription_approval_status: Series::SUBSCRIPTION_PRX_APPROVED,
                      subscriber_only_at: Time.now)
      story = create(:story, series_id: series.id)
      Story.where(id: story.id).must_include story
      Story.where(id: story.id).series_visible.wont_include story
    end

    it 'wont include non-v4 stories' do
      story = create(:story)
      story.app_version.must_equal 'v4'
      Story.where(id: story.id).v4.must_include story
      story.update_attributes(app_version: 'v3', deleted_at: nil)
      Story.where(id: story.id).v4.wont_include story
      story.update_attributes(app_version: 'foobar', deleted_at: nil)
      Story.where(id: story.id).v4.wont_include story
    end

    it 'searches text for title and description' do
      story = create(:story,
                     title: 'Some Weirdo',
                     description: 'Unique thing',
                     short_description: 'Lacking sense')

      Story.match_text('weirdo').must_include story
      Story.match_text('unique').must_include story
      Story.match_text('lack').must_include story
      Story.match_text('random').wont_include story
    end

    it 'returns public only stories' do
      story = create(:story)
      story_n = create(:story, network_only_at: Time.now)
      series = create(:series,
                      subscription_approval_status: Series::SUBSCRIPTION_PRX_APPROVED,
                      subscriber_only_at: Time.now)
      story_s = create(:story, series_id: series.id)
      story_u = create(:story, published_at: nil)

      Story.public_stories.must_include story
      Story.public_stories.wont_include story_n
      Story.public_stories.wont_include story_s
      Story.public_stories.wont_include story_u
    end
  end

  describe 'default scope' do
    it 'includes non-deleted v3 stories' do
      story = create(:story_v3)
      Story.where(id: story.id).must_include story
    end

    it 'does not include deleted v3 stories' do
      story = create(:story_v3)
      story.destroy!
      story.deleted_at.wont_be_nil
      Story.where(id: story).wont_include story
    end

    it 'includes non-deleted v4 stories' do
      story = create(:story, deleted_at: nil, app_version: 'v4')
      Story.where(id: story.id).must_include story
    end

    it 'includes "deleted" v4 stories' do
      story = create(:story, deleted_at: Time.now, app_version: 'v4')
      Story.where(id: story.id).must_include story
    end
  end
end
