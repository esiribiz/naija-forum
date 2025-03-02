class CategoriesController < ApplicationController
before_action :authenticate_user!, except: [:index, :show]
before_action :set_category, only: [:show, :edit, :update, :destroy]

# GET /categories
def index
    @categories = policy_scope(Category)
end

# GET /categories/1
def show
authorize @category
end

# GET /categories/new
def new
@category = Category.new
authorize @category
end

# GET /categories/1/edit
def edit
authorize @category
end

# POST /categories
def create
@category = Category.new(category_params)
authorize @category

if @category.save
    redirect_to @category, notice: 'Category was successfully created.'
else
    render :new, status: :unprocessable_entity
end
end

# PATCH/PUT /categories/1
def update
authorize @category
if @category.update(category_params)
    redirect_to @category, notice: 'Category was successfully updated.'
else
    render :edit, status: :unprocessable_entity
end
end

# DELETE /categories/1
def destroy
authorize @category
@category.destroy
redirect_to categories_url, notice: 'Category was successfully deleted.'
end

  private

  # Find category by ID
  def set_category
    @category = Category.find(params[:id])  # ✅ Fixed
  end

  # Only allow trusted parameters
  def category_params
    params.require(:category).permit(:name, :description, :image, :color)  # ✅ Added `:image`
  end
end
