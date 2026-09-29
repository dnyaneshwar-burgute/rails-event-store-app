import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async signOut(event) {
    event.preventDefault()
    const clerk = await this.#waitForClerk()
    await clerk.load()
    await clerk.signOut({ redirectUrl: "/" })
  }

  #waitForClerk() {
    if (window.Clerk) return Promise.resolve(window.Clerk)

    return new Promise((resolve, reject) => {
      const startedAt = Date.now()
      const timer = window.setInterval(() => {
        if (window.Clerk) {
          window.clearInterval(timer)
          resolve(window.Clerk)
        } else if (Date.now() - startedAt > 10000) {
          window.clearInterval(timer)
          reject(new Error("Clerk failed to load"))
        }
      }, 50)
    })
  }
}
