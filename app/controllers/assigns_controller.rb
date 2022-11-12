class AssignsController < ApplicationController
  before_action :authenticate_user!
  before_action :email_exist?, only: [:create]
  before_action :user_exist?, only: [:create]

  def create
    team = find_team(params[:team_id])
    user = email_reliable?(assign_params) ? User.find_or_create_by_email(assign_params) : nil
    if user
      team.invite_member(user)
      redirect_to team_url(team), notice: I18n.t('views.messages.assigned')
    else
      redirect_to team_url(team), notice: I18n.t('views.messages.failed_to_assign')
    end
  end

  def destroy
    assign = Assign.find(params[:id])
    destroy_message = assign_destroy(assign, assign.user)

    redirect_to team_url(params[:team_id]), notice: destroy_message
  end

  private
  def assign_params
    params[:email]
  end

  #元
  # def assign_destroy(assign, assigned_user)
  #   if assigned_user == assign.team.owner                       # チームオーナーが自ら削除しようとした場合
  #     I18n.t('views.messages.cannot_delete_the_leader')           # リーダーは削除できません
  #   elsif Assign.where(user_id: assigned_user.id).count == 1    # チームに所属しているアサインユーザの数が1つの場合
  #     I18n.t('views.messages.cannot_delete_only_a_member')        # このメンバーしか所属していないので削除できません
  #   elsif assign.destroy                                        # チームメンバーを削除した場合
  #     set_next_team(assign, assigned_user)
  #     I18n.t('views.messages.delete_member')                      # メンバーを削除しました
  #   else                                                        # メンバーを削除できなかった場合
  #     I18n.t('views.messages.cannot_delete_member_4_some_reason') # 削除できませんでした
  #   end
  # end

  def assign_destroy(assign, assigned_user)
    if assigned_user == assign.team.owner # アサイン(チームに入っている)ユーザとチームオーナーが一緒の場合（チームオーナーを削除しようとした場合）
      I18n.t('views.messages.cannot_delete_the_leader')
    elsif Assign.where(user_id: assigned_user.id).count == 1 # アサインユーザー(チームメンバー)が1人の場合
      I18n.t('views.messages.cannot_delete_only_a_member')
    elsif current_user.id != assigned_user.id #　ログインしているユーザと削除するアサインユーザが異なる場合（自分以外のユーザを削除しようとした場合）
      if current_user.id == assign.team.owner.id # ログインしている(削除しようとしている)ユーザがチームオーナーだった場合（要件）
        assign.destroy                           # 削除できる
        set_next_team(assign, assigned_user)     # 削除した後、チームメンバー情報を更新する？
        I18n.t('views.messages.delete_member')
      else # ログインしている(削除しようとしている)ユーザがチームオーナーではなかった場合
        I18n.t('views.messages.cannot_delete_another_member') # 他のチームメンバーを削除できない
      end
    elsif current_user.id != assign.team.owner.id # ログインしている(削除しようとしている)ユーザがチームオーナーではなかった場合
      if current_user.id == assigned_user.id #　ログインしている(削除しようとしている)ユーザとアサインユーザが一緒の場合（User自身のこと）
        assign.destroy                       # 削除できる
        set_next_team(assign, assigned_user)
        I18n.t('views.messages.delete_member')
      else #　ログインしている(削除しようとしている)ユーザとアサインユーザが異なる場合（自分以外のメンバーを削除しようとした場合）
        I18n.t('views.messages.only_leader_can_delete_a_member') # リーダーのみメンバーを削除することができる
      end
    elsif assign.destroy # チームメンバーを削除できた場合
      set_next_team(assign, assigned_user)
      I18n.t('views.messages.delete_member')
    else # チームメンバーを削除できなかった(削除に失敗した)場合
      I18n.t('views.messages.cannot_delete_member_4_some_reason')
    end
  end

  # def assign_destroy(assign, assigned_user)
  #   if  assigned_user == assign.team.owner
  #     I18n.t('views.messages.cannot_delete_the_leader')
  #   elsif Assign.where(user_id: assigned_user.id).count == 1
  #     I18n.t('views.messages.cannot_delete_only_a_member')
  #   elsif current_user.id == assign.team.owner.id || current_user.id == assigned_user.id
  #     assign.destroy
  #     set_next_team(assign, assigned_user)
  #     I18n.t('views.messages.delete_member')
  #   elsif current_user.id != assigned_user.id
  #     I18n.t('views.messages.only_leader_can_delete_a_member')
  #   else
  #     I18n.t('views.messaes.cannot_delete_member_4_some_reason')
  #   end
  # end

  def email_exist?
    team = find_team(params[:team_id])
    if team.members.exists?(email: params[:email])
      redirect_to team_url(team), notice: I18n.t('views.messages.email_already_exists')
    end
  end

  def email_reliable?(address)
    address.match(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
  end

  def user_exist?
    team = find_team(params[:team_id])
    unless User.exists?(email: params[:email])
      redirect_to team_url(team), notice: I18n.t('views.messages.does_not_exist_email')
    end
  end

  def set_next_team(assign, assigned_user)
    another_team = Assign.find_by(user_id: assigned_user.id).team # アサインユーザを取り出して、そのユーザの所属しているチームを変数に入れる
    change_keep_team(assigned_user, another_team) if assigned_user.keep_team_id == assign.team_id # チームのユーザ情報を保存(更新)する？（change_keep_team:application_controller.rb）
  end

  def find_team(team_id)
    Team.friendly.find(params[:team_id])
  end
end
