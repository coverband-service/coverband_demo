class Post < ApplicationRecord
  ###
  # example method to show multiple call paths
  # logic in a method, that can be traced
  #
  # this is not an example of good code ;)
  ###
  def self.clear_bad_posts(all: false)
    posts = Post.all
    bad_posts = posts.select { |post| post.title.blank? || post.body.blank? }
    if all
      bad_posts.destroy_all!
    else
      bad_posts.first&.destroy!
    end
  end

  def formatted_title
    title.titleize
  end
end
