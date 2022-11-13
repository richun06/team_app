class ContactMailer < ApplicationMailer
  def contact_mail(emails)
    # 個別送付:@user = agenda.user
    @user = emails
    mail to: @user, subject: "アジェンダと紐づく記事とコメント削除のメール"
  end
end
