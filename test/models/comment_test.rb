require "test_helper"

class CommentTest < ActiveSupport::TestCase
setup do
@user = User.create!(
    username: "testuser",
    email: "test@example.com",
    password: "password123",
    password_confirmation: "password123"
)
@category = Category.create!(name: "Test Category")
@post = Post.create!(
    title: "Test Post",
    body: "Test Content",
    user: @user,
    category: @category
)
end

test "preserves safe HTML content" do
    comment = Comment.new(
    content: "<p><strong>Hello</strong> <em>World</em></p>",
    post: @post,
    user: @user
    )
    comment.save
    assert_equal "<p><strong>Hello</strong> <em>World</em></p>", comment.content
end

test "removes unsafe HTML content" do
    unsafe_html = '<p>Hello</p><script>alert("bad")</script><div onclick="bad()">Click</div>'
    comment = Comment.new(content: unsafe_html, post: @post, user: @user)
    comment.save
    assert_equal "<p>Hello</p><div>Click</div>", comment.content
end

test "processes HTML on save" do
    comment = Comment.new(content: "Initial", post: @post, user: @user)
    comment.save
    comment.content = "<p>Safe</p><script>unsafe()</script>"
    comment.save
    assert_equal "<p>Safe</p>", comment.content
end

test "converts plain URLs to clickable links" do
    comment = Comment.new(
        content: "Check out https://example.com and http://test.com",
        post: @post,
        user: @user
    )
    comment.save
    assert_includes comment.content, '<a href="https://example.com" target="_blank" rel="noopener noreferrer">https://example.com</a>'
    assert_includes comment.content, '<a href="http://test.com" target="_blank" rel="noopener noreferrer">http://test.com</a>'
end

test "preserves existing HTML links while adding security attributes" do
    comment = Comment.new(
        content: 'Visit <a href="https://example.com">Example</a>',
        post: @post,
        user: @user
    )
    comment.save
    assert_includes comment.content, '<a href="https://example.com" target="_blank" rel="noopener noreferrer">Example</a>'
end

test "auto-links URLs alongside HTML sanitization" do
    comment = Comment.new(
        content: '<p>Check https://safe.com</p><script>alert("bad")</script> http://another.com',
        post: @post,
        user: @user
    )
    comment.save
    assert_includes comment.content, '<p>Check <a href="https://safe.com" target="_blank" rel="noopener noreferrer">https://safe.com</a></p>'
    assert_includes comment.content, '<a href="http://another.com" target="_blank" rel="noopener noreferrer">http://another.com</a>'
    refute_includes comment.content, "<script>"
end
end
