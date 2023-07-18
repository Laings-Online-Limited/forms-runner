class Question::EmailComponent::EmailComponentPreview < ViewComponent::Preview
  def email_field
    question = OpenStruct.new(email: "example@gov.uk",
                              answer_type: "email",
                              question_text: "What is your email?",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::EmailComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def email_field_with_hint
    question = OpenStruct.new(email: "example@gov.uk",
                              answer_type: "email",
                              question_text: "What is your email?",
                              hint_text: "eg: Joe.Bloggs@example.com",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::EmailComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
