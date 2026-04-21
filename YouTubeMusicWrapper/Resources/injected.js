(function () {
  'use strict';

  if (window.__ymw && window.__ymw.__installed) return;

  const post = (payload) => {
    try {
      window.webkit.messageHandlers.trackInfo.postMessage(payload);
    } catch (e) {
      // handler not available yet
    }
  };

  const SELECTORS = {
    playerBar: 'ytmusic-player-bar',
    title: '.title.ytmusic-player-bar',
    byline: '.byline.ytmusic-player-bar',
    thumbnail: '.image.ytmusic-player-bar',
    playPauseButton: '#play-pause-button',
    nextButton: '.next-button',
    previousButton: '.previous-button',
  };

  const getVideo = () => document.querySelector('video');
  const getMoviePlayer = () => document.querySelector('#movie_player');

  const text = (el) => (el && el.textContent) ? el.textContent.trim() : '';

  const parseBylinePieces = (raw) => {
    if (!raw) return { artist: '', album: null };
    const parts = raw.split(/\s*•\s*/);
    const artist = parts[0] || '';
    const album = parts.length >= 3 ? parts[1] : null;
    return { artist, album };
  };

  const getArtworkURL = () => {
    const img = document.querySelector(SELECTORS.thumbnail + ' img, ' + SELECTORS.thumbnail);
    if (!img) return null;
    const src = img.currentSrc || img.src || null;
    if (!src) return null;
    return src.replace(/=w\d+-h\d+/, '=w544-h544');
  };

  const snapshot = () => {
    const video = getVideo();
    const title = text(document.querySelector(SELECTORS.title));
    if (!title) return null;

    const rawByline = text(document.querySelector(SELECTORS.byline));
    const { artist, album } = parseBylinePieces(rawByline);

    const duration = video && isFinite(video.duration) ? video.duration : 0;
    const position = video && isFinite(video.currentTime) ? video.currentTime : 0;
    const isPlaying = !!(video && !video.paused && !video.ended && video.readyState > 2);

    return {
      title,
      artist,
      album,
      artworkURL: getArtworkURL(),
      duration,
      position,
      isPlaying,
    };
  };

  let lastSent = null;
  const sendIfChanged = (force) => {
    const s = snapshot();
    if (!s) return;
    const same = lastSent
      && lastSent.title === s.title
      && lastSent.artist === s.artist
      && lastSent.album === s.album
      && lastSent.artworkURL === s.artworkURL
      && lastSent.isPlaying === s.isPlaying
      && Math.abs((lastSent.duration || 0) - (s.duration || 0)) < 0.5
      && Math.abs((lastSent.position || 0) - (s.position || 0)) < 0.5;
    if (!force && same) return;
    lastSent = s;
    post(s);
  };

  const attachVideoListeners = (video) => {
    if (!video || video.__ymwBound) return;
    video.__ymwBound = true;
    ['play', 'pause', 'ratechange', 'seeked', 'durationchange', 'loadedmetadata', 'ended'].forEach((ev) => {
      video.addEventListener(ev, () => sendIfChanged(true));
    });
    // periodic position updates while playing
    video.addEventListener('timeupdate', () => {
      sendIfChanged(false);
    });
  };

  const observer = new MutationObserver(() => {
    attachVideoListeners(getVideo());
    sendIfChanged(false);
  });

  const startObserving = () => {
    attachVideoListeners(getVideo());
    observer.observe(document.body, { subtree: true, childList: true, characterData: true });
    // periodic fallback in case MutationObserver misses a change
    setInterval(() => sendIfChanged(false), 2000);
    sendIfChanged(true);
  };

  const click = (sel) => {
    const el = document.querySelector(sel);
    if (el) el.click();
  };

  const api = {
    __installed: true,
    play: () => {
      const mp = getMoviePlayer();
      if (mp && typeof mp.playVideo === 'function') { mp.playVideo(); return; }
      const v = getVideo();
      if (v && v.paused) click(SELECTORS.playPauseButton);
    },
    pause: () => {
      const mp = getMoviePlayer();
      if (mp && typeof mp.pauseVideo === 'function') { mp.pauseVideo(); return; }
      const v = getVideo();
      if (v && !v.paused) click(SELECTORS.playPauseButton);
    },
    toggle: () => click(SELECTORS.playPauseButton),
    next: () => {
      const mp = getMoviePlayer();
      if (mp && typeof mp.nextVideo === 'function') { mp.nextVideo(); return; }
      click(SELECTORS.nextButton);
    },
    previous: () => {
      const mp = getMoviePlayer();
      if (mp && typeof mp.previousVideo === 'function') { mp.previousVideo(); return; }
      click(SELECTORS.previousButton);
    },
    seekTo: (seconds) => {
      const mp = getMoviePlayer();
      if (mp && typeof mp.seekTo === 'function') {
        mp.seekTo(seconds, true);
        return;
      }
      const v = getVideo();
      if (v) v.currentTime = seconds;
    },
  };

  window.__ymw = api;

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startObserving, { once: true });
  } else {
    startObserving();
  }
})();
