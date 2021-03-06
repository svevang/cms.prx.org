# encoding: utf-8

class EpisodeImportJob < ApplicationJob
  queue_as :cms_default

  def perform(episode_import)
    episode_import.import
  end
end
