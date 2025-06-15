export default {
  mounted() {
    this.el.innerText = this.formatTimeSince(this.el);
  },
  updated() {
    this.el.innerText = this.formatTimeSince(this.el);
  },
  formatTimeSince(node) {
    let timestamp = node.dataset.timestamp;

    let parsedTimestamp = Date.parse(timestamp);

    let elapsedTime = Date.now() - parsedTimestamp;

    const millisecondsPerSecond = 1000;
    const secondsInMinute = 60;
    const secondsInHour = secondsInMinute * 60;
    const secondsInDay = secondsInHour * 24;

    const secondsSince = Math.floor(elapsedTime / millisecondsPerSecond);

    if (secondsSince > secondsInDay) {
      return `${Math.floor(secondsSince / secondsInDay)} days ago`;
    } else if (secondsSince > secondsInHour) {
      return `${Math.floor(secondsSince / secondsInHour)} hours ago`;
    } else if (secondsSince > secondsInMinute) {
      return `${Math.floor(secondsSince / secondsInMinute)} minutes ago`;
    } else {
      return `Just now`;
    }
  },
};
