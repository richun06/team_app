class AgendasController < ApplicationController
  # before_action :set_agenda, only: %i[show edit update destroy]

  def index
    @agendas = Agenda.all
  end

  def new
    @team = Team.friendly.find(params[:team_id])
    @agenda = Agenda.new
  end

  def create
    @agenda = current_user.agendas.build(title: params[:title])
    @agenda.team = Team.friendly.find(params[:team_id])
    current_user.keep_team_id = @agenda.team.id
    if current_user.save && @agenda.save
      redirect_to dashboard_url, notice: I18n.t('views.messages.create_agenda')
    else
      render :new
    end
  end

  def destroy
    @agenda = Agenda.find(params[:id])
    if current_user.id == @agenda.user.id || current_user.id == @agenda.team.owner.id
      @agenda.destroy
      redirect_to dashboard_url, notice: "#{@agenda.title}を削除しました。"
      @keep_team_id = @agenda.team_id
      user_emails = User.where(keep_team_id: @keep_team_id).pluck(:email)
      user_emails.each do |emails|
        ContactMailer.contact_mail(emails).deliver
      end
    else
      redirect_to dashboard_url, notice: "権限がないため削除できません。"
    end
  end

  private

  def set_agenda
    @agenda = Agenda.find(params[:id])
  end

  def agenda_params
    params.fetch(:agenda, {}).permit %i[title description]
  end
end
