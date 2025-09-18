class CommentsController < ApplicationController
before_action :authenticate_user!, except: [:index]
before_action :set_post
before_action :set_comment, only: [:edit, :update, :destroy]

def index
    @comments = policy_scope(@post.comments)
      .includes(:user, :children)
      .top_level
      .order(created_at: :desc)
end

def create
    @comment = current_user.comments.build(comment_params)
    @comment.post = @post
    authorize @comment
    
    respond_to do |format|
    if @comment.save
        message = @comment.parent_id.present? ? 'Reply was successfully added.' : 'Comment was successfully created.'
        format.html { redirect_to post_path(@post), notice: message }
        format.turbo_stream {
        Rails.logger.info "Creating comment via Turbo Stream for comment ID: #{@comment.id}"
        if @comment.parent_id.present?
            Rails.logger.info "Comment is a reply to parent #{@comment.parent_id}"
            render turbo_stream: [
            turbo_stream.append("comment_#{@comment.parent_id}_replies", 
                partial: 'comments/comment',
                locals: { comment: @comment }
            ),
            turbo_stream.replace("reply_form_#{@comment.parent_id}",
                partial: 'comments/form',
                locals: { comment: Comment.new(parent_id: @comment.parent_id), post: @post }
            )
            ]
        else
            Rails.logger.info "Comment is a top-level comment, appending to post_comments"
            render turbo_stream: [
            turbo_stream.append("post_comments",
                partial: 'comments/comment',
                locals: { comment: @comment }
            ),
            turbo_stream.replace("new_comment",
                partial: "comments/form",
                locals: { comment: Comment.new, post: @post }
            )
            ]
        end
        }
    else
        format.html { redirect_to post_path(@post), alert: 'Error creating comment.' }
        format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
            @comment.parent_id.present? ? "reply_form_#{@comment.parent_id}" : "new_comment",
            partial: "comments/form",
            locals: { comment: @comment, post: @post }
        )
        }
    end
    end
end

def edit
    @post = @comment.post
    authorize @comment
end

def update
    authorize @comment
    if @comment.update(comment_params)
    redirect_to @comment.post, notice: 'Comment was successfully updated.'
    else
    render :edit
    end
end

def destroy
    authorize @comment
    @post = @comment.post
    comment_id = @comment.id

    @comment.destroy!

    respond_to do |format|
    format.html { redirect_to post_path(@post), notice: 'Comment was successfully deleted.' }
    format.turbo_stream { 
        render turbo_stream: turbo_stream.remove("comment_#{comment_id}")
    }
    end
end

private

def set_post
    @post = Post.includes(:user, :category, :comments).find(params[:post_id])
end

def set_comment
    @comment = Comment.find(params[:id])
end

def comment_params
    params.require(:comment).permit(:content, :parent_id)
end
end
