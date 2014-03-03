TestObject = Struct.new(:title)
TestObject.send(:extend, ActiveModel::Naming)

class Api::TestObjectRepresenter < Api::BaseRepresenter

  property :title

  def api_tests_path(rep)
    title = rep.respond_to?('[]') ? rep[:title] : rep.try(:title)
    "/api/tests/#{title}"
  end

  link :self do
    api_tests_path(represented)
  end
end

test_routes = Proc.new do
  namespace :api do
    resources :test_objects
  end
end
Rails.application.routes.eval_block(test_routes)
