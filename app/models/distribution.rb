# encoding: utf-8
require 'hash_serializer'

class Distribution < BaseModel
  belongs_to :distributable, polymorphic: true, touch: true
  belongs_to :audio_version_template

  has_many :story_distributions
  has_many :distribution_templates, dependent: :destroy, autosave: true
  has_many :audio_version_templates, through: :distribution_templates
  serialize :properties, HashSerializer

  def distribute!
    # no op for the super class
  end

  # default to the generic distro, override in subclass
  def story_distribution_class
    StoryDistribution
  end

  def create_story_distribution(story)
    story_distribution_class.create(distribution: self, story: story).tap(&:distribute!)
  end

  def owner
    distributable
  end

  def account
    if owner.is_a?(Account)
      owner
    else
      owner.try(:account)
    end
  end

  def kind
    (type || 'Distribution').safe_constantize.model_name.element.sub(/_distribution$/, '')
  end

  def kind=(k)
    child_class = "Distributions::#{k.titleize}Distribution".safe_constantize if k
    if child_class
      self.type = child_class.name
    end
  end

  def self.class_for_kind(k)
    child_class = "Distributions::#{k.titleize}Distribution".safe_constantize if k
    child_class || Distribution
  end

  def self.policy_class
    AccountablePolicy
  end
end
