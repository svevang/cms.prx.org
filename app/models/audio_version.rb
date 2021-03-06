# encoding: utf-8

class AudioVersion < BaseModel

  include ValidityFlag

  belongs_to :story, -> { with_deleted },
             class_name: 'Story',
             foreign_key: 'piece_id', touch: true

  belongs_to :audio_version_template
  has_many :audio_files, -> { order :position }, dependent: :destroy

  before_save :set_status, only: [:update, :create]
  after_commit :update_story_status
  after_destroy :update_story_status

  acts_as_paranoid

  def length(reload=false)
    @_length = nil if reload
    @_length ||= audio_files.inject(0) { |sum, f| sum + f.length.to_i }
  end

  alias_method :duration, :length

  def self.policy_class
    StoryAttributePolicy
  end

  def compliant_with_template?
    status_message.nil?
  end

  private

  def audio_formats_match?
    %i(content_type layer frequency bit_rate channel_mode).each do |format|
      return false if audio_files.map(&format).compact.uniq.length > 1
    end
    true
  end

  def update_story_status
    return unless story
    story.with_lock do
      story.save!
    end
  end

  def set_status
    noncompliant_files = audio_files.select do |af|
      !af.compliant_with_template? || af.status == INVALID
    end
    if !noncompliant_files.empty?
      self.status = INVALID
      self.status_message = noncompliant_files.map(&:status_message).join(', ')
      return
    end

    if !audio_formats_match?
      self.status = INVALID
      self.status_message = 'Audio file formats do not match'
      return
    end

    errors = audio_version_template.try(:validate_audio_version, self)
    if !errors.blank?
      self.status = INVALID
      self.status_message = errors
      return
    end

    pos = 0
    if audio_files.detect { |af| af.position != (pos += 1) }
      self.status = INVALID
      self.status_message = "Audio file missing for position #{pos}"
      return
    end

    self.status = COMPLETE
    self.status_message = nil
  end
end
