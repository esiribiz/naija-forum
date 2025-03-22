class TagsController < ApplicationController
before_action :set_tag, only: [:show, :edit, :update, :destroy]
after_action :verify_authorized, except: :index
after_action :verify_policy_scoped, only: :index

def index
    @tags = policy_scope(Tag)
end

def show
    authorize @tag
    @posts = @tag.posts
end

def new
    @tag = Tag.new
    authorize @tag
end

def edit
    authorize @tag
end

def create
    @tag = Tag.new(tag_params)
    authorize @tag

    if @tag.save
    redirect_to @tag, notice: 'Tag was successfully created.'
    else
    render :new
    end
end

def update
    authorize @tag
    if @tag.update(tag_params)
    redirect_to @tag, notice: 'Tag was successfully updated.'
    else
    render :edit
    end
end

def destroy
    authorize @tag
    @tag.destroy
    redirect_to tags_url, notice: 'Tag was successfully destroyed.'
end

private

def set_tag
    @tag = Tag.find(params[:id])
end

def tag_params
    params.require(:tag).permit(:name)
end
end
