import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "recipient", "destroyInput"]

  add(event) {
    event.preventDefault()
    
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    
    const recipient = event.currentTarget.closest("[data-nested-form-target='recipient']")
    const destroyInput = recipient.querySelector("[data-nested-form-target='destroyInput']")
    
    if (destroyInput) {
      destroyInput.value = "1"
      recipient.style.display = "none"
    } else {
      recipient.remove()
    }
  }
}

