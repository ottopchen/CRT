# == Schema Information
#
# Table name: data_types
#
#  id         :integer          not null, primary key
#  formula    :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  order      :integer
#  master     :boolean          default(FALSE)
#  input_type :integer          default(0)
#

class DataTypesController < ApplicationController
  def index
    @specific_data_types = DataType.where(master: false).order(:order)
    @master_data_types = DataType.where(master: true).order(:order)
  end

  def new
    @specific_data_types = DataType.where(master: false).order(:order)
    @master_data_types = DataType.where(master: true).order(:order)
    @data_type = DataType.new
  end

  def edit
    @data_type = DataType.find(params[:id])
    @data_types = DataType.where(master: @data_type.master?).order(:order)
  end

  def create
    @data_type = DataType.new(data_type_params)
    @data_type.order = DataType.where(master: @data_type.master).size + 1

    if @data_type.save
      if @data_type.master?
        Project.master_project.create_data_type(@data_type)
      else
        Project.create_data_type_for_specific_projects(@data_type)
      end
      redirect_to action: "index"
    else
      flash[:errors] = @data_type.errors.full_messages.first
      redirect_to action: "new"
    end
  end

  def update
    @data_type = DataType.find(params[:id])

    previous_order = @data_type.order
    new_order = data_type_params[:order].to_i
    master_type = @data_type.master?
    if new_order <= DataType.where(master: master_type).size && new_order > 0
      detect_order_change(previous_order, new_order, master_type)
    end

    cleaned_data_type_params = data_type_params
    cleaned_data_type_params[:formula] = nil if data_type_params[:formula] == ''
    if @data_type.update(cleaned_data_type_params)
      redirect_to action: "index"
    else
      flash[:errors] = @data_type.errors.full_messages.first
      redirect_to action: "edit"
    end
  end

  def destroy
    deleted_data_type_order = DataType.find(params[:id]).order
    type = params[:master] ? true : false
    @data_types = DataType.where(master: type).order(:order)
    DataType.transaction do
      DataType.destroy params[:id]
      @data_types.each do |data_type|
        if data_type.order > deleted_data_type_order
          data_type.order = data_type.order - 1
          fail data_type.errors.to_full_messages unless data_type.save
        end
      end
    end


    redirect_to action: "index"
  end

  private

  def data_type_params
    data_type_hash = params.require(:data_type).permit(:name, :formula, :order, :master, :input_type)
    data_type_hash[:formula] = data_type_hash[:formula].blank? ? nil : data_type_hash[:formula]
    data_type_hash
  end

  # rearrange order number of the corresponding data types.
  def detect_order_change(previous_order, new_order, type)
    if previous_order != new_order
      DataType.transaction do
        @data_types_to_update = DataType.where(master: type).order(:order)
        @data_types_to_update.each do |data_type|
          if previous_order < new_order
            if data_type.order <= new_order && data_type.order > previous_order
              data_type.order = data_type.order - 1
              fail "Update ordering failed" unless data_type.save
            end
          elsif data_type.order >= new_order && data_type.order < previous_order
            data_type.order = data_type.order + 1
            fail "Update ordering failed" unless data_type.save
          end
        end
      end
    end
  end
end
