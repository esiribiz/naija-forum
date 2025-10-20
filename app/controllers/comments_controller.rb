class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_post
  before_action :set_comment, only: [:show, :edit, :update, :destroy, :cancel_edit]

  def index
    @comments = @post.comments.includes(:user, :replies).where(parent_id: nil).order(created_at: :desc)
  end

  def new
    @comment = @post.comments.new(parent_id: params[:parent_id])
    authorize @comment

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "reply-form-#{params[:parent_id]}",
          partial: "comments/reply_form",
          locals: { comment: @comment, post: @post, parent_id: params[:parent_id] }
        )
      }
      format.html
    end
  end

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    authorize @comment

    respond_to do |format|
      if @comment.save
        format.turbo_stream {
          if @comment.parent_id.present?
            # This is a reply to an existing comment
            render turbo_stream: [
              turbo_stream.append(
                "comment_#{@comment.parent_id}_replies",
                partial: "comments/comment",
                locals: { comment: @comment, post: @post }
              ),
              turbo_stream.replace("reply-form-#{@comment.parent_id}", "")
            ]
          else
            # This is a top-level comment
            render turbo_stream: [
              turbo_stream.prepend(
                "post_comments",
                partial: "comments/comment",
                locals: { comment: @comment, post: @post }
              ),
              turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: Comment.new, post: @post })
            ]
          end
        }
        format.html { redirect_to post_path(@post), notice: "Comment added successfully." }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "reply-form-#{@comment.parent_id}",
            partial: "comments/reply_form",
            locals: { comment: @comment, post: @post, parent_id: @comment.parent_id }
          )
        }
        format.html { render :new }
      end
    end
  end

  def edit
    authorize @comment

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "comment_#{@comment.id}",
          partial: "comments/edit_comment_form",
          locals: { comment: @comment, post: @post }
        )
      }
      format.html
    end
  end

  def update
    authorize @comment
    if @comment.update(comment_params)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "comment_#{@comment.id}",
            partial: "comments/comment",
            locals: { comment: @comment, post: @post }
          )
        }
        format.html { redirect_to post_path(@post), notice: "Comment updated." }
      end
      else
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "comment_#{@comment.id}",
              partial: "comments/edit_comment_form",
              locals: { comment: @comment, post: @post }
            )
          }
          format.html { render :edit }
        end
      end
  end

  def cancel_edit
    authorize @comment

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "comment_#{@comment.id}",
          partial: "comments/comment",
          locals: { comment: @comment, post: @post }
        )
      }
      format.html { redirect_to post_path(@post) }
    end
  end

  def destroy
    authorize @comment
    @comment.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("comment_#{@comment.id}") }
      format.html { redirect_to post_path(@post), notice: "Comment deleted." }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end
end
