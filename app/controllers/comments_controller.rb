class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_post
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  def index
    @comments = @post.comments.includes(:user, :replies).where(parent_id: nil).order(created_at: :desc)
  end

  def new
    @comment = @post.comments.new(parent_id: params[:parent_id])
    authorize @comment

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "reply-form-#{@comment.parent_id}",
          partial: "comments/reply_form",
          locals: { comment: @comment, post: @post }
        )
      }
      format.html # Render the new.html.erb template for direct navigation
    end
  end

  def create
    @comment = current_user.comments.build(comment_params)
    @comment.post = @post
    authorize @comment

    respond_to do |format|
      if @comment.save
        format.turbo_stream {
          if @comment.parent_id.present?
            render turbo_stream: [
              turbo_stream.append(
                "comment_#{@comment.parent_id}_replies",
                partial: "comments/reply",
                locals: { reply: @comment }
              ),
              turbo_stream.replace("reply-form-#{@comment.parent_id}", "")
            ]
          else
            render turbo_stream: [
              turbo_stream.append(
                "post_comments",
                partial: "comments/comment",
                locals: { comment: @comment, post: @post }
              ),
              turbo_stream.replace(
                "new_comment",
                partial: "comments/form",
                locals: { comment: Comment.new, post: @post }
              )
            ]
          end
        }
        format.html { redirect_to post_path(@post), notice: "Comment added successfully." }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            @comment.parent_id.present? ? "reply-form-#{@comment.parent_id}" : "new_comment",
            partial: "comments/form",
            locals: { comment: @comment, post: @post }
          )
        }
        format.html {
          if @comment.parent_id.present?
            # For reply forms, render the new template with errors
            render :new
          else
            redirect_to post_path(@post), alert: @comment.errors.full_messages.join(", ")
          end
        }
      end
    end
  end

  def edit
    authorize @comment
    
    # Check if comment can still be edited
    unless @comment.can_be_edited_by?(current_user)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "shared/error", locals: { message: "Comment can no longer be edited (2-minute limit expired)." }) }
        format.html { redirect_to post_path(@post), alert: "Comment can no longer be edited (2-minute limit expired)." }
      end
      return
    end
    
    respond_to do |format|
      format.turbo_stream {
        if @comment.parent_id.present?
          # For replies - replace the reply with edit form
          render turbo_stream: turbo_stream.replace(
            "reply_#{@comment.id}",
            partial: "comments/edit_reply_form",
            locals: { comment: @comment, post: @post }
          )
        else
          # For top-level comments - replace the comment with edit form
          render turbo_stream: turbo_stream.replace(
            "comment_#{@comment.id}",
            partial: "comments/edit_comment_form",
            locals: { comment: @comment, post: @post }
          )
        end
      }
      format.html # Render the edit.html.erb template for direct navigation
    end
  end

  def update
    authorize @comment
    
    # Check if comment can still be edited
    unless @comment.can_be_edited_by?(current_user)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "shared/error", locals: { message: "Comment can no longer be edited (2-minute limit expired)." }) }
        format.html { redirect_to post_path(@post), alert: "Comment can no longer be edited (2-minute limit expired)." }
      end
      return
    end
    
    respond_to do |format|
      if @comment.update(comment_params)
        format.turbo_stream {
          if @comment.parent_id.present?
            render turbo_stream: turbo_stream.replace(
              "reply_#{@comment.id}",
              partial: "comments/reply",
              locals: { reply: @comment }
            )
          else
            render turbo_stream: turbo_stream.replace(
              "comment_#{@comment.id}",
              partial: "comments/comment",
              locals: { comment: @comment, post: @post }
            )
          end
        }
        format.html { redirect_to post_path(@post), notice: "Comment updated successfully." }
      else
        format.turbo_stream {
          render :edit
        }
        format.html { render :edit }
      end
    end
  end

  def destroy
    authorize @comment
    
    # Check if comment can still be deleted
    unless @comment.can_be_deleted_by?(current_user)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "shared/error", locals: { message: "Comment can no longer be deleted (2-minute limit expired)." }) }
        format.html { redirect_to post_path(@post), alert: "Comment can no longer be deleted (2-minute limit expired)." }
      end
      return
    end
    
    respond_to do |format|
      if @comment.destroy
        format.turbo_stream { render turbo_stream: turbo_stream.remove("comment_#{@comment.id}") }
        format.html { redirect_to post_path(@post), notice: "Comment deleted." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "shared/error", locals: { message: "Could not delete comment." }) }
        format.html { redirect_to post_path(@post), alert: "Could not delete comment." }
      end
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
