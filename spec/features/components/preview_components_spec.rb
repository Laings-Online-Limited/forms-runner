require "rails_helper"

describe "Previewing components", type: :feature do
  it "checks all component previews for axe errors" do
    visit "/preview/"
    links = page.all("li > a").map { |a| a["href"] }
    links.each do |link|
      visit link
      expect_component_to_have_no_axe_errors(page)
    end
  end
end
