require_relative '../test_helper'

class PostTest < ActiveSupport::TestCase
  test 'clear_bad_posts clears all bad posts' do
    Post.create!(title: 'bad post', body: '')
    Post.create!(title: 'bad post2', body: '')
    original = Post.all.count
    Post.clear_bad_posts(all: true)
    assert_equal (original - 2), Post.all.count
  end

  test 'clear_bad_posts clears one bad post' do
    Post.create!(title: 'bad post', body: '')
    Post.create!(title: 'bad post2', body: '')
    original = Post.all.count
    Post.clear_bad_posts(all: false)
    assert_equal (original - 1), Post.all.count
  end

  test 'clear_bad_posts dangerously can throw exceptions' do
    assert_raise NoMethodError do
      Post.clear_bad_posts(dangerous: true)
    end
  end
end
