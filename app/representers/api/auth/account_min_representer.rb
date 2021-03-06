# encoding: utf-8

class Api::Auth::AccountMinRepresenter < Api::Min::AccountRepresenter
  # point to authorized stories (including unpublished)
  link :stories do
    {
      href: "#{api_authorization_account_stories_path(represented)}#{index_url_params}",
      templated: true,
      count: represented.stories.count
    }
  end
  embed :stories,
        paged: true,
        item_class: Story,
        item_decorator: Api::Auth::StoryMinRepresenter,
        zoom: false

  def self_url(r)
    api_authorization_account_path(r)
  end
end
