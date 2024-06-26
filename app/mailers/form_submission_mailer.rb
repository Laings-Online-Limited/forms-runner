class FormSubmissionMailer < GovukNotifyRails::Mailer
  def email_confirmation_input(text_input:, notify_response_id:, submission_email:, mailer_options:)
    set_template(Settings.govuk_notify.form_submission_email_template_id)

    set_personalisation(
      title: mailer_options.title,
      text_input:,
      submission_time: mailer_options.timestamp.strftime("%l:%M%P").strip,
      submission_date: mailer_options.timestamp.strftime("%-d %B %Y"),
      # GOV.UK Notify's templates have conditionals, but only positive
      # conditionals, so to simulate negative conditionals we add two boolean
      # flags; but they must always have opposite values!
      test: make_notify_boolean(mailer_options.preview_mode),
      not_test: make_notify_boolean(!mailer_options.preview_mode),
      submission_reference: mailer_options.submission_reference,
      include_payment_link: make_notify_boolean(mailer_options.payment_url.present?),
    )

    set_reference(notify_response_id)

    set_email_reply_to(Settings.govuk_notify.form_submission_email_reply_to_id)

    mail(to: submission_email)
  end

private

  def make_notify_boolean(bool)
    bool ? "yes" : "no"
  end
end
