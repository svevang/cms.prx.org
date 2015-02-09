# encoding: utf-8

class Api::MusicalWorkRepresenter < Api::BaseRepresenter

  property :id
  property :position
  property :title
  property :artist
  property :label
  property :album
  property :year
  property :excerpt_length, as: :length

  def self_url(musical_work)
    polymorphic_path([:api, musical_work.story, musical_work])
  end
end
