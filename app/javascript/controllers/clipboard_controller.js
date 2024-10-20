import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source"];

  copy() {
    navigator.clipboard
      .writeText(this.sourceTarget.dataset.clipboardText)
      .then(() => {
        alert("Copied to clipboard!");
      })
      .catch((err) => {
        console.error("Failed to copy: ", err);
      });
  }
}
