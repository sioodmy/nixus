/* Only mark presentation nodes. No message text, storage or requests are read. */
module.exports = () => {
  if (window.__amethystMessengerObserver) return;
  const regions = '[data-scope="messages_table"], [role="log"], [role="grid"]';
  let pending = false;
  const scan = () => {
    pending = false;
    for (const region of document.querySelectorAll(regions)) {
      // Conversation lists also use grids; scope to actual message rows.
      if (!region.matches('[data-scope="messages_table"], [role="log"]') &&
          !region.querySelector('[data-scope="messages_table"], [data-message-id], [data-testid*="message"], [role="row"] [dir="auto"]')) continue;
      const texts = region.querySelectorAll('[dir="auto"], [data-testid="mw_message_bubble"]');
      for (const text of Array.from(texts).slice(-400)) {
        if (text.closest('[contenteditable="true"], button, [role="button"], [data-aero-message]')) continue;
        let bubble = text;
        for (let depth = 0; bubble && bubble !== region && depth < 6; depth++, bubble = bubble.parentElement) {
          if (bubble.matches('[role="row"], [role="gridcell"]')) break;
          if (bubble.querySelector('img, video, canvas, [role="img"], [contenteditable="true"]')) continue;
          const style = getComputedStyle(bubble);
          const color = style.backgroundColor;
          const painted = color !== 'transparent' && color !== 'rgba(0, 0, 0, 0)';
          const rounded = Math.max(parseFloat(style.borderTopLeftRadius), parseFloat(style.borderTopRightRadius)) >= 8;
          const rect = bubble.getBoundingClientRect();
          if ((!painted && style.backgroundImage === 'none') || !rounded || rect.width < 16 || rect.height < 15) continue;
          const bounds = region.getBoundingClientRect();
          if (rect.width > bounds.width * .95 || rect.height > Math.max(240, bounds.height * .6)) continue;
          const right = bounds.right - rect.right;
          const left = rect.left - bounds.left;
          bubble.dataset.aeroMessage = right < left ? 'outgoing' : 'incoming';
          break;
        }
      }
    }
  };
  const schedule = () => {
    if (pending) return;
    pending = true;
    // Coalesce React mutations and virtualized scrolling into one small pass.
    setTimeout(() => requestAnimationFrame(scan), 100);
  };
  const observer = new MutationObserver(schedule);
  observer.observe(document.body, { childList: true, subtree: true });
  window.addEventListener('resize', schedule, { passive: true });
  window.__amethystMessengerObserver = observer;
  scan();
};
