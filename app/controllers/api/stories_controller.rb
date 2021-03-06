# encoding: utf-8

class Api::StoriesController < Api::BaseController
  api_versions :v1

  filter_resources_by :series_id, :account_id, :network_id

  filter_params :highlighted, :purchased, :v4, :text

  sort_params default: { published_at: :desc, updated_at: :desc },
              allowed: [:id, :created_at, :updated_at, :published_at, :title,
                        :episode_number, :position]

  announce_actions :create, :update, :destroy, :publish, :unpublish

  def after_create_resource(res)
    res.create_story_distributions
  end

  def after_update_resource(res)
    series_dists = res.try(:series).try(:distributions)

    story_template_ids = res
      .try(:audio_versions)
      .try(:map) { |av| av.audio_version_template_id }
      .try(:compact)

    if series_dists && story_template_ids
      missing_dists = series_dists.select do |series_dist|
        # story has version with series dist template, but has no matching story dist
        story_template_ids.include?(series_dist.audio_version_template_id) &&
        res.distributions.none? { |story_dist| story_dist.distribution == series_dist }
      end
    end

    missing_dists.try(:each) { |series_dist| res.create_single_story_distribution(series_dist) }
  end

  def publish
    publish_resource.tap do |res|
      authorize res
      res.publish!
      respond_with root_resource(res), create_options
    end
  end

  def publish_resource
    @story ||= Story.where(id: params[:id]).first
  end

  def unpublish
    unpublish_resource.tap do |res|
      authorize res
      res.unpublish!
      respond_with root_resource(res), create_options
    end
  end

  def unpublish_resource
    @story ||= Story.where(id: params[:id]).first
  end

  def random
    @story = Story.public_stories.limit(1).order('RAND()').first
    show
  end

  def create_resource
    super.tap do |story|
      story.creator_id = current_user.id
      story.account_id ||= story.series.try(:account_id)

      if account && authorization.authorized?(account)
        story.account_id ||= account.id
      end

      if authorization.authorized?(current_user.default_account)
        story.account_id ||= current_user.account_id
      end

      story.account_id ||= authorization.token_auth_accounts.first.try(:id)
    end
  end

  private

  def resources_base
    if highlighted?
      account.portfolio_stories
    else
      super
    end
  end

  def filtered(resources)
    resources = resources.v4 if filters.v4?
    resources = resources.match_text(filters.text) if filters.text?
    if highlighted?
      resources
    else
      super
    end
  end

  def included(relation)
    relation.includes(
      { audio_versions: [:audio_files] },
      { promos: [:audio_files] },
      { account: [:image, :address, { opener: [:image] }] },
      { series: [:images, :account, :audio_version_templates] },
      :creator,
      :images,
      :license,
      :topics,
      :tones,
      :formats,
      :distributions,
      :user_tags
    )
  end

  def scoped(relation)
    relation.public_stories
  end

  def sorted(res)
    res = res.purchased.order('purchase_count DESC') if filters.purchased?
    super(res)
  end

  def highlighted?
    account && filters.highlighted?
  end

  def account
    @account ||= Account.find(params[:account_id]) if params[:account_id]
  end
end
