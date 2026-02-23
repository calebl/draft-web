import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.handleSystemChange = this.handleSystemChange.bind(this)

    this.applyTheme()
    this.mediaQuery.addEventListener("change", this.handleSystemChange)
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.handleSystemChange)
  }

  handleSystemChange() {
    if (this.element.dataset.themePreference === "system") {
      this.applySystemTheme()
    }
  }

  applyTheme() {
    const pref = this.element.dataset.themePreference
    if (pref === "system") {
      this.applySystemTheme()
    } else {
      this.element.dataset.theme = pref
    }
  }

  applySystemTheme() {
    const isDark = this.mediaQuery.matches
    this.element.dataset.theme = isDark ? "dark" : "light"
  }
}
