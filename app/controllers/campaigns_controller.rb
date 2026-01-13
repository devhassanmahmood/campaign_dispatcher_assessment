class CampaignsController < ApplicationController
  before_action :set_campaign, only: [:show, :start_dispatch]

  def index
    @campaigns = Campaign.order(created_at: :desc).to_a
  end

  def show
  end

  def new
    @campaign = Campaign.new
    @campaign.recipients.build
  end

  def create
    @campaign = Campaign.new(campaign_params)

    if @campaign.save
      redirect_to @campaign, notice: "Campaign created successfully."
    else
      @campaign.recipients.build if @campaign.recipients.empty?
      render :new, status: :unprocessable_content
    end
  end

  def start_dispatch
    DispatchCampaignJob.perform_later(@campaign.id)
    redirect_to @campaign, notice: "Campaign dispatch started."
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, recipients_attributes: [:id, :name, :email, :phone, :_destroy])
  end
end
