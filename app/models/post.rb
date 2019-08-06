class Post < ApplicationRecord
  ###
  # example method to show multiple call paths
  # logic in a method, that can be traced
  #
  # This is not an example of good code, just a quick way to highlight some functionality ;)
  ###
  def self.clear_bad_posts(all: false, dangerous: false)
    posts = Post.all
    bad_posts = posts.select { |post| post.title.blank? || post.body.blank? }
    if all || bad_posts&.length == 1
      bad_posts.map(&:destroy!)
    elsif dangerous
      bad_posts.first.destroy!
    else
      bad_posts.first&.destroy!
    end
  end

  def formatted_title
    title.titleize
  end
end
