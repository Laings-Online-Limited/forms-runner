class StepFactory
  START_PAGE = "_start".freeze
  PAGE_SLUG_REGEX = Regexp.union([/\d+/, Regexp.new(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)])

  class PageNotFoundError < StandardError
    def initialize(msg = "Page not found.")
      super
    end
  end

  def initialize(form:)
    @form = form
  end

  def create_step(page_slug_or_start)
    # Normalize the id or constant passed in
    page_slug = page_slug_or_start.to_s == START_PAGE ? @form.start_page : page_slug_or_start
    page_slug = page_slug.to_s

    return CheckYourAnswersStep.new(form_id: @form.id) if page_slug == CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG

    # for now, we use the page id as slug
    page = @form.pages.find { |p| p.id.to_s == page_slug }
    raise PageNotFoundError, "Can't find page #{page_slug}" if page.nil?

    next_page_slug = page.has_next_page? ? page.next_page.to_s : CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG
    goto_page_slug = page.routing_conditions.empty? ? nil : page.routing_conditions.first.goto_page_id.to_s
    question = QuestionRegister.from_page(page)

    Step.new(question:, page_id: page.id, form_id: @form.id, form_slug: @form.form_slug, next_page_slug:, page_slug:, page_number: page.number(@form), routing_conditions: page.routing_conditions, goto_page_slug:)
  end

  def start_step
    create_step(START_PAGE)
  end
end
