# == Schema Information
#
# Table name: data_values
#
#  id              :integer          not null, primary key
#  type            :integer
#  value           :decimal(, )
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  data_type_id    :integer          not null
#  project_year_id :integer          not null
#  formula_value   :decimal(, )
#
# Indexes
#
#  index_data_values_on_data_type_id  (data_type_id)
#
# Foreign Keys
#
#  fk_rails_886dbffcc0  (data_type_id => data_types.id)
#

class DataValuesController < ApplicationController
  def destroy
    DataValue.destroy params[:id]
  end

  def update
    @data_value = DataValue.find(params[:id])
    @data_value.update(data_value_params)
    @project = Project.find(@data_value.project)
    @data_types = DataType.where(master: @project.master?).order(:order)
    @data_values = DataValue.all
    ParseFormulaService.update_data_values(@project, @data_types, @data_values)
    render json: @data_value.project.data_values
  end

  private

  def data_value_params
    params.require(:data_value).permit(:value, :data_type_id)
  end
end
