require "test_helper"

class PostTest < ActiveSupport::TestCase
test "removes unsafe HTML content" do
    post = Post.new(
    title: "Test",
    body: "<p>Hello</p><script>alert(\"bad\")</script><div onclick=\"bad()\">Click</div>"
    )
    post.save
    assert_equal "<p>Hello</p><div>Click</div>", post.body
end

test "processes HTML on save" do
    post = Post.new(title: "Test", body: "<p>Safe</p><script>unsafe()</script>")
    post.save
    assert_equal "<p>Safe</p>", post.body
end

test "converts plain URLs to clickable links" do
    post = Post.new(
    title: "Test",
    body: "Check out https://example.com and http://test.com"
    )
    post.save
    assert_includes post.body, "<a href=\"https://example.com\" target=\"_blank\" rel=\"noopener noreferrer\">https://example.com</a>"
end

test "preserves existing HTML links while adding security attributes" do
    post = Post.new(
    title: "Test",
    body: "Visit <a href=\"https://example.com\">Example</a>"
    )
    post.save
    assert_includes post.body, "<a href=\"https://example.com\" target=\"_blank\" rel=\"noopener noreferrer\">Example</a>"
end

test "auto-links URLs alongside HTML sanitization" do
    post = Post.new(
    title: "Test",
    body: "<p>Check https://safe.com</p><script>alert(\"bad\")</script> http://another.com"
    )
    post.save
    assert_includes post.body, "<p>Check <a href=\"https://safe.com\" target=\"_blank\" rel=\"noopener noreferrer\">https://safe.com</a></p>"
end

test "preserves safe HTML content" do
    post = Post.new(title: "Test", body: "<p><strong>Hello</strong> <em>World</em></p>")
    post.save
    assert_equal "<p><strong>Hello</strong> <em>World</em></p>", post.body
end
end
