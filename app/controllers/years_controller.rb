class YearsController < ApplicationController
  def index
    @years = Year.all
  end

  def show
    @year = Year.find(params[:id])
  end

  def new
    @year = Year.new
  end

  def edit
    @year = Year.find(params[:id])
  end

  def create
    @year = Year.new(year_params)
    if @year.save
      @year.create_project_years
    else
      render 'new'
    end
    redirect_to years_path
  end

  def update
    @year = Year.find(params[:id])

    if @year.update(year_params)
      redirect_to @year
    else
      render 'edit'
    end
  end

  def destroy
    Year.destroy params[:id]

    redirect_to years_path
  end

  private

  def year_params
    params.require(:year).permit(:date)
  end
end