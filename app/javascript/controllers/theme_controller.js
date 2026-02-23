import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.handleSystemChange = this.handleSystemChange.bind(this)

    if (this.element.dataset.themePreference === "system") {
      this.applySystemTheme()
      this.mediaQuery.addEventListener("change", this.handleSystemChange)
    }
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.handleSystemChange)
  }

  handleSystemChange() {
    if (this.element.dataset.themePreference === "system") {
      this.applySystemTheme()
    }
  }

  applySystemTheme() {
    const isDark = this.mediaQuery.matches
    this.element.dataset.theme = isDark ? "dark" : "light"
  }
}
