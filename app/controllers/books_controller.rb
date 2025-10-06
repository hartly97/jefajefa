class BooksController < ApplicationController

  before_action :authenticate_user!, only: [:edit, :update, :destroy] #:show,

  before_action :set_book, only: [:show, :edit, :update, :destroy]

  def remedybook
  end

  def apothecary
  end

  def recipes
  end

  def thumbnails
    @books = Book.all
  end

  def index
    @books = Book.order(sort_this_column + " "  + sort_this_direction).paginate(page: params[:page], per_page: 50)
    # Book.order(page_number: :desc)
  end

  def edit
    @book = Book.find(params[:id])
  end

  def new
    @book = Book.new
    #add_breadcrumb('New')
  end

  def create
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book, notice: 'Book was successfully created.'
    else
      render :new
    end
  end

  def show
    @book = Book.find(params[:id])
  end

  def update
    if @book.update(book_params)
      redirect_to book_path(@book), notice: 'Book was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @book = Book.find(params[:id])
        if @book.destroy
        flash[:danger] = "Book was deleted successfully."
        redirect_to books_path
      else
        flash.now[:alert] = "There was an error deleting the book."
        render :show
        end
  end

  private

  def authorize_user
    unless current_user.admin?
      flash[:alert] = "Sorry you aren't an admin"
      redirect_to welcome_index_path
    end
  end

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:name, :page_number, :description, :transcription, :transcriptiontwo, :image, :content) #images: []
  end

  def sort_this_column
    Book.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_this_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
