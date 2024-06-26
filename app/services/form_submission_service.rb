class FormSubmissionService
  class << self
    def call(**args)
      new(**args)
    end
  end

  MailerOptions = Data.define(:title, :preview_mode, :timestamp, :submission_reference, :payment_url)

  def initialize(logging_context:, current_context:, request:, email_confirmation_input:, preview_mode:)
    @logging_context = logging_context
    @current_context = current_context
    @request = request
    @form = current_context.form
    @email_confirmation_input = email_confirmation_input
    @requested_email_confirmation = @email_confirmation_input.send_confirmation == "send_email"
    @preview_mode = preview_mode
    @timestamp = submission_timestamp
    @submission_reference = ReferenceNumberService.generate

    @mailer_options = MailerOptions.new(title: form_title,
                                        preview_mode: @preview_mode,
                                        timestamp: @timestamp,
                                        submission_reference: @submission_reference,
                                        payment_url: @form.payment_url_with_reference(@submission_reference))

    @logging_context[:submission_reference] = @submission_reference
  end

  def submit
    submit_form_to_processing_team
    submit_confirmation_email_to_user
    @submission_reference
  end

  def submit_form_to_processing_team
    raise StandardError, "Form id(#{@form.id}) has no completed steps i.e questions/answers to include in submission email" if @current_context.completed_steps.blank?

    if !@preview_mode && @form.submission_email.blank?
      raise StandardError, "Form id(#{@form.id}) is missing a submission email address"
    end

    unless @form.submission_email.blank? && @preview_mode

      mail = FormSubmissionMailer
      .email_confirmation_input(text_input: email_body,
                                notify_response_id: @email_confirmation_input.submission_email_reference,
                                submission_email: @form.submission_email,
                                mailer_options: @mailer_options).deliver_now

      @logging_context[:notification_ids] ||= {}
      @logging_context[:notification_ids][:submission_email_id] = mail.govuk_notify_response.id
    end

    LogEventService.log_submit(@logging_context, @current_context, requested_email_confirmation: @requested_email_confirmation, preview: @preview_mode)
  end

  def submit_confirmation_email_to_user
    return nil unless @form.what_happens_next_markdown.present? && has_support_contact_details?
    return nil unless @requested_email_confirmation

    mail = FormSubmissionConfirmationMailer.send_confirmation_email(
      what_happens_next_markdown: @form.what_happens_next_markdown,
      support_contact_details: formatted_support_details,
      notify_response_id: @email_confirmation_input.confirmation_email_reference,
      confirmation_email_address: @email_confirmation_input.confirmation_email_address,
      mailer_options: @mailer_options,
    ).deliver_now

    @logging_context[:notification_ids] ||= {}
    @logging_context[:notification_ids][:confirmation_email_id] = mail.govuk_notify_response.id
  end

  class NotifyTemplateBodyFilter
    def build_question_answers_section(current_context)
      current_context.completed_steps.map { |page|
        [prep_question_title(page.question_text),
         prep_answer_text(page.show_answer_in_email)].join
      }.join("\n\n---\n\n").concat("\n")
    end

    def prep_question_title(question_text)
      "# #{question_text}\n"
    end

    def prep_answer_text(answer)
      return "\\[This question was skipped\\]" if answer.blank?

      escape(answer)
    end

    def escape(text)
      text
        .then { normalize_whitespace _1 }
        .then { replace_setext_headings _1 }
        .then { escape_markdown_text _1 }
    end

    def escape_markdown_text(text)
      url_regex = URI::DEFAULT_PARSER.make_regexp(%w[http https])
      a = ""
      rest = text
      until rest.empty?
        head, match, rest = rest.partition(url_regex)
        a << escape_markdown_characters(head)
        a << match
      end
      a
    end

    def normalize_whitespace(text)
      text.strip.gsub(/\r\n?/, "\n").split(/\n\n+/).map(&:strip).join("\n\n")
    end

    def escape_markdown_characters(text)
      replaced = { "^" => "", "•" => "" }
      escaped = %w{! " # ' ` ( ) * + - . [ ] _ \{ | \} ~}.index_with { |c| "\\#{c}" }

      changes = replaced.merge(escaped)

      to_change = Regexp.union(changes.keys)
      text.gsub(to_change, changes)
    end

    def replace_setext_headings(text)
      # replace lengths of ^===$ with --- to stop them making headings
      text.gsub(/^(=+)$/) { "_" * Regexp.last_match(1).length }
    end
  end

private

  def form_title
    @form.name
  end

  def email_body
    FormSubmissionService::NotifyTemplateBodyFilter.new.build_question_answers_section(@current_context)
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end

  def has_support_contact_details?
    [@form.support_email, @form.support_phone].any?(&:present?) || [@form.support_url, @form.support_url_text].all?(&:present?)
  end

  def formatted_support_details
    return nil unless has_support_contact_details?

    [support_phone_details, support_email_details, support_online_details].compact_blank.join("\n\n")
  end

  def support_phone_details
    return nil if @form.support_phone.blank?

    notify_body = NotifyTemplateBodyFilter.new
    formatted_phone_number = notify_body.normalize_whitespace(@form.support_phone)

    "#{formatted_phone_number}\n\n[#{I18n.t('support_details.call_charges')}](#{@current_context.support_details.call_back_url})"
  end

  def support_email_details
    return nil if @form.support_email.blank?

    "[#{@form.support_email}](mailto:#{@form.support_email})"
  end

  def support_online_details
    return nil if [@form.support_url, @form.support_url_text].all?(&:blank?)

    "[#{@form.support_url_text}](#{@form.support_url})"
  end
end
