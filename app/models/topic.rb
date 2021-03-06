# encoding: utf-8

class Topic < BaseModel
  TOPIC_NAMES = ['African-American', 'Art', 'Asian', 'Business', 'Children', 'Drama', 'Education',
                 'Entertainment', 'Environment', 'Family', 'Food', 'Garden', 'Gay and Lesbian',
                 'Historical', 'Historical Anniversaries', 'Holidays', 'Humor', 'Instructional',
                 'International', 'Labor', 'Latino', 'Literature', 'Media', 'Music', 'Native',
                 'News', 'Politics', 'Public Affairs', 'Religious', 'Science', 'Senior', 'Sports',
                 'Technology', 'Travel', 'War', 'Women', 'Youth'].freeze

  belongs_to :story, class_name: 'Story', foreign_key: 'piece_id', touch: true

  validates_inclusion_of :name, in: TOPIC_NAMES
  validates_uniqueness_of :name, scope: :story

  def to_tag
    name
  end

  def self.policy_class
    StoryAttributePolicy
  end
end
