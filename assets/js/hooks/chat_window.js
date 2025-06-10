export default {
    mounted() {

        const eventName = this.el.dataset.eventName
        console.log(this.el)
        console.log(eventName)

        this.el.addEventListener(eventName, scrollIntoView(this))
        this.el.addEventListener(`phx:${eventName}`, scrollIntoView(this))

        console.log(this.el.childNodes)

        observer = new MutationObserver(childNodeAdded)
        observer.observe(this.el, { childList: true })
    }
}

function scrollIntoView(self) {
    return function (e) {
        const messageNodes = self.el.querySelectorAll('[data-container-type="message"]')
        switch (e.detail.direction) {
            case "top":
                messageNodes.item(0).scrollIntoView({ behavior: 'smooth', block: "start" })
                break
            case "bottom":
                const lastIndex = messageNodes.length - 1

                messageNodes.item(lastIndex).scrollIntoView({ behavior: 'smooth', block: "end" })
                break
            default:
                console.error("Don't know what this is", e.detail.direction)
        }
    }
}

function childNodeAdded(mutationList, observer) {
    for (const mutation of mutationList) {
        if (mutation.type === "childList") {
            for (let node of mutation.addedNodes) {
                if (node.dataset && node.dataset.containerType === "message") {
                    node.scrollIntoView({ behavior: 'smooth', block: "end" })
                }
            }

        }
    }
}