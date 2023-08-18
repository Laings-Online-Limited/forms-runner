require "rails_helper"

RSpec.describe Question::NameComponent::View, type: :component do
  let(:extra_question_text_suffix) { nil }
  let(:with_title) { "false" }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render_inline(described_class.new(form_builder:, question:, extra_question_text_suffix:))
  end

  describe "when component is full name field" do
    let(:question) { build :full_name_question, with_title: }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 1 text fields and include autocomplete" do
      expect(page.find_all("input[type='text']").length).to eq 1
      expect(page).to have_css("input[type='text'][name='form[full_name]'][autocomplete='name']")
    end

    context "when the question has hint text" do
      let(:question) { build :full_name_question, :with_hints }

      it "outputs the hint text" do
        expect(page.find(".govuk-hint")).to have_text(question.hint_text)
      end
    end

    context "when there is extra suffix to be added to heading" do
      let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

      it "renders the question text and extra suffix as a heading" do
        expect(page.find("h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
      end
    end

    context "with unsafe question text" do
      let(:question) { build :full_name_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1 label").native.inner_html).to eq(expected_output)
      end
    end

    context "when component includes title" do
      let(:with_title) { "true" }

      it "renders 2 text fields (Title and full name) and include autocomplete" do
        expect(page.find_all("input[type='text']").length).to eq 2
        expect(page).to have_css("input[type='text'][name='form[title]'][autocomplete='honorific-prefix']")
        expect(page).to have_css("input[type='text'][name='form[full_name]'][autocomplete='name']")
      end
    end
  end

  describe "when component is first, middle and last name field" do
    let(:middle_names) { nil }
    let(:question) { build :first_middle_last_name_question, with_title:, middle_names: }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders two text inputs (First name and last name) and includes autocomplete" do
      expect(page.find_all("input[type='text']").length).to eq 2
      expect(page).to have_css("input[type='text'][name='form[first_name]'][autocomplete='given-name']")
      expect(page).to have_css("input[type='text'][name='form[last_name]'][autocomplete='family-name']")
    end

    context "when the question has hint text" do
      let(:question) { build :first_middle_last_name_question, :with_hints }

      it "outputs the hint text" do
        expect(page.find(".govuk-hint")).to have_text(question.hint_text)
      end
    end

    context "when there is extra suffix to be added to heading" do
      let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

      it "renders the question text and extra suffix as a heading" do
        expect(page.find("h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
      end
    end

    context "with unsafe question text" do
      let(:question) { build :first_middle_last_name_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end

    context "when component includes title" do
      let(:with_title) { "true" }

      it "renders 3 text fields (Title, first name and last name) and include autocomplete" do
        expect(page.find_all("input[type='text']").length).to eq 3
        expect(page).to have_css("input[type='text'][name='form[title]'][autocomplete='honorific-prefix']")
        expect(page).to have_css("input[type='text'][name='form[first_name]'][autocomplete='given-name']")
        expect(page).to have_css("input[type='text'][name='form[last_name]'][autocomplete='family-name']")
      end
    end

    context "when component includes middle names" do
      let(:middle_names) { "Marks Haag" }

      it "renders 3 text fields (Title, first name and last name) and include autocomplete" do
        expect(page.find_all("input[type='text']").length).to eq 3
        expect(page).to have_css("input[type='text'][name='form[first_name]'][autocomplete='given-name']")
        expect(page).to have_css("input[type='text'][name='form[middle_names]'][autocomplete='additional-name']")
        expect(page).to have_css("input[type='text'][name='form[last_name]'][autocomplete='family-name']")
      end
    end
  end
end
