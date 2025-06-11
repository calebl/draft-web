# frozen_string_literal: true

class OutlineItemsController < ApplicationController
  before_action :story
  before_action :outline_item, only: %i[show update destroy]

  def new
    redirect_to_home unless can? :create, @story

    @outline_item = @outline.outline_items.new
  end

  def show
    redirect_to_home unless can? :read, @story
  end

  def create
    redirect_to_home unless can? :create, @story

    item_params[:text].each_line do |text|
      @outline.outline_items.create(text:) if text.present?
    end

    redirect_to story_outline_path(@story), status: :see_other
  end

  def update
    redirect_to_home unless can? :update, @story

    if item_params[:text].to_s.empty?
      @outline_item.destroy
    else
      @outline_item.set_list_position(item_params[:position]) if item_params[:position]
      @outline_item.update item_params
    end

    redirect_to story_outline_path(@story), status: :see_other
  end

  def destroy
    redirect_to_home unless can? :destroy, @story

    @outline_item.destroy
    head :ok
  end

  private

  def item_params
    params.require(:outline_item).permit(:text, :completed, :position)
  end

  def story
    @story = Story.find(params[:story_id])
    @outline = @story.outline || Outline.create(story_id: @story.id)
  end

  def outline_item
    @outline_item = OutlineItem.find(params[:id])
  end
end
